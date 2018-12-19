"""
Module to give access to location of build Git repositories
in Cornice; yes, the method MUST be called 'includeme'
"""


def includeme(config):
    """
    Get build Git repository directory and make it accessible
    to all requests generated via Cornice
    """

    # Make DB connection accessible as a request property
    def _get_repos(request):
        _settings = request.registry.settings
        repo_dir = _settings['repo_basedir']

        return repo_dir

    config.add_request_method(_get_repos, 'repo_dir', reify=True)
