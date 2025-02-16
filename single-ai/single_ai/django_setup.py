import os

import django
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'single_ai.settings')
os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
django.setup()
