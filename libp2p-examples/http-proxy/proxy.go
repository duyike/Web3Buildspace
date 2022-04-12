package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/libp2p/go-libp2p"
	"github.com/libp2p/go-libp2p-core/host"
	"github.com/libp2p/go-libp2p-core/network"
	"github.com/libp2p/go-libp2p-core/peer"
	"github.com/libp2p/go-libp2p-core/peerstore"
	ma "github.com/multiformats/go-multiaddr"
	manet "github.com/multiformats/go-multiaddr/net"
)

const Protocol = "/proxy-example/0.0.1"

type ProxyService struct {
	host host.Host
	dest peer.ID
	proxyAddr ma.Multiaddr
}

var _ http.Handler = &ProxyService{}

func NewProxyService(h host.Host, dest peer.ID, proxyAddr ma.Multiaddr) *ProxyService {
	h.SetStreamHandler(Protocol, streamHandler)

	fmt.Println("Proxy server is ready")
	fmt.Println("libp2p-peer addresses:")
	for _, a := range h.Addrs() {
		fmt.Printf("%s/ipfs/%s\n", a, peer.Encode(h.ID()))
	}

	return &ProxyService{
		host:      h,
		dest:      dest,
		proxyAddr: proxyAddr,
	}
}

func streamHandler(stream network.Stream) {
	// Remember to close the stream when we are done.
	defer stream.Close()
	// Create a new buffered reader, as ReadRequest needs one.
	// The buffered reader reads from our stream, on which we
	// have sent the HTTP request (see ServeHTTP())
	buf :=bufio.NewReader(stream)
	req, err := http.ReadRequest(buf)
	if err != nil {
		stream.Reset()
		log.Println(err)
		return
	}
	// We need to reset these fields in the request
	// URL as they are not maintained.
	req.URL.Scheme = "http"
	hp := strings.Split(req.Host, ":")
	if len(hp) > 1 && hp[1] == "443" {
		req.URL.Scheme = "https"
	}
	req.URL.Host = req.Host

	outreq := new(http.Request)
	*outreq = *req
	// We now make the request
	fmt.Printf("Making request to %s\n", req.URL)
	resp, err := http.DefaultTransport.RoundTrip(outreq)
	if err != nil {
		stream.Reset()
		log.Println(err)
		return 
	}
	// resp.Write writes whatever response we obtained for our
	// request back to the stream.
	resp.Write(stream)
}

func (p *ProxyService) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("proxying request for %s to peer %s\n", r.URL, p.dest.Pretty())
	// We need to send the request to the remote libp2p peer, so
	// we open a stream to it
	stream, err := p.host.NewStream(context.Background(), p.dest, Protocol)
	// If an error happens, we write an error for response.
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer stream.Close()

	// r.Write() writes the HTTP request to the stream.
	err = r.Write(stream)
	if err != nil {
		stream.Reset()
		log.Println(err)
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	// Now we read the response that was sent from the dest
	// peer
	buf := bufio.NewReader(stream)
	resp, err := http.ReadResponse(buf, r)
	if err != nil {
		stream.Reset()
		log.Println(err)
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	// Copy any headers
	for k, v := range resp.Header {
		for _, s := range v {
			w.Header().Add(k, s)
		}
	}
	// Write response status and headers
	w.WriteHeader(resp.StatusCode)
	// Finally, copy the body
	io.Copy(w, resp.Body)
	resp.Body.Close()
}

func (p *ProxyService) Serve()  {
	_, ip, err := manet.DialArgs(p.proxyAddr)
	if err != nil {
		log.Fatalln(err)
	}
	log.Println("proxy listening on ", ip)
	if p.dest != "" {
		err = http.ListenAndServe(ip, p)
		if err != nil {
			log.Fatalln(err)
		}
	}
}

func makeRandomHost(port int) host.Host {
	h, err := libp2p.New(libp2p.ListenAddrStrings(fmt.Sprintf("/ip4/127.0.0.1/tcp/%d", port)))
	if err != nil {
		log.Fatalln(err)
	}
	return h
}

func addAddrToPeerstore(h host.Host, dest string) peer.ID {
	// The following code extracts target's the peer ID from the
	// given multiaddress
	ipfsAddr, err := ma.NewMultiaddr(dest)
	if err != nil {
		log.Fatalln(err)
	}
	pid, err := ipfsAddr.ValueForProtocol(ma.P_IPFS)
	if err != nil {
		log.Fatalln(err)
	}
	peerID, err := peer.Decode(pid)
	if err != nil {
		log.Fatalln(err)
	}

	// Decapsulate the /ipfs/<peerID> part from the target
	// /ip4/<a.b.c.d>/ipfs/<peer> becomes /ip4/<a.b.c.d>
	targerPeerAddr, _ := ma.NewMultiaddr(fmt.Sprintf("/ipfs/%s", peer.Encode(peerID)))
	targetAddr := ipfsAddr.Decapsulate(targerPeerAddr)

	// We have a peer ID and a targetAddr so we add
	// it to the peerstore so LibP2P knows how to contact it
	h.Peerstore().AddAddr(peerID, targetAddr, peerstore.PermanentAddrTTL)
	return peerID
}

const help = `
This example creates a simple HTTP Proxy using two libp2p peers. The first peer
provides an HTTP server locally which tunnels the HTTP requests with libp2p
to a remote peer. The remote peer performs the requests and 
send the sends the response back.
Usage: Start remote peer first with:   ./proxy
       Then start the local peer with: ./proxy -d <remote-peer-multiaddress>
Then you can do something like: curl -x "localhost:9900" "http://ipfs.io".
This proxies sends the request through the local peer, which proxies it to
the remote peer, which makes it and sends the response back.`

func main() {
	// usage
	flag.Usage = func() {
		fmt.Println(help)
		flag.PrintDefaults()
	}
	// Parse some flags
	destPeer := flag.String("d", "", "destination peer")
	port := flag.Int("p", 9900, "proxy port")
	p2pPort := flag.Int("l", 12000, "p2p listen port")
	flag.Parse()

	if *destPeer == "" {
		h := makeRandomHost(*p2pPort)
		_ = NewProxyService(h, "", nil)
		<- make(chan struct{})
	} else {
		h := makeRandomHost(*p2pPort + 1)
		destPeerID := addAddrToPeerstore(h, *destPeer)
		proxyAddr, err := ma.NewMultiaddr(fmt.Sprintf("/ip4/127.0.0.1/tcp/%d", *port))
		if err != nil {
			log.Fatalln(err)
		}
		proxy := NewProxyService(h, destPeerID, proxyAddr)
		proxy.Serve()
	}
}


