"""
URLs for all supported endpoints

For the build and commit endpoints, this includes the full REST path
endpoints along with the alternate concise path endpoints
"""

ALL_URLS = dict(
    build_collection='/products/{product_name}/releases/{release_name}'
                     '/versions/{product_version}/builds',
    build='/products/{product_name}/releases/{release_name}'
          '/versions/{product_version}/builds/{build_num}',
    build_alt_collection='/builds',
    build_alt='/builds/{build_key}',
    commit_collection='/projects/{project_name}/commits',
    commit='/projects/{project_name}/commits/{commit_sha}',
    commit_alt_collection='/commits',
    commit_alt='/commits/{commit_key}',
    project_collection='/projects',
    project='/projects/{project_name}',
    product_collection='/products',
    product='/products/{product_name}',
    release_collection='/products/{product_name}/releases',
    release='/products/{product_name}/releases/{release_name}',
    version_collection='/products/{product_name}/releases/{release_name}'
                       '/versions',
    version='/products/{product_name}/releases/{release_name}'
            '/versions/{product_version}',
)
