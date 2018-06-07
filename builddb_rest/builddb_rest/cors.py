"""
Default CORS configuration for all Cornice @resources
"""

CORS_POLICY = dict(
    headers=('Content-Type',),
    origins=('*',)
)
