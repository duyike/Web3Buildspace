from django.db import models


class SystemPrompt(models.Model):
    name = models.CharField(max_length=255, unique=True)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = '"single_ai"."system_prompts"'
        verbose_name = 'System Prompt'
        verbose_name_plural = 'System Prompts'

    def __str__(self):
        return self.name


class Agent(models.Model):
    handle = models.CharField(max_length=255, unique=True, db_index=True)
    status = models.CharField(
        max_length=50,
        choices=[
            ('pending', 'Pending'),
            ('completed', 'Completed'),
            ('failed', 'Failed'),
        ],
        default='pending'
    )
    prompt = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = '"single_ai"."agents"'
        verbose_name = 'Agent'
        verbose_name_plural = 'Agents'

    def __str__(self):
        return f"{self.handle} ({self.status})"


class Chat(models.Model):
    handle = models.CharField(max_length=255, db_index=True)
    message = models.TextField()
    response = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = '"single_ai"."chats"'
        verbose_name = 'Chat'
        verbose_name_plural = 'Chats'
        indexes = [
            models.Index(fields=['handle', 'created_at'], name='chat_handle_created_idx')
        ]

    def __str__(self):
        return f"{self.handle} - {self.created_at}"
