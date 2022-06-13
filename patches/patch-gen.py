#!/usr/bin/env python3
from pathlib import Path

import click
from jinja2 import Template

openssl = {
    "mac": {
        "lib": "./openssl/lib/",
        "include": "./openssl/include/",
    },
    "win": {
        "lib": ".\\openssl",
        "include": ".\\openssl\\include",
    },
    "linux": {
        "lib": "/usr/local/ssl/lib/",
        "include": "/usr/local/ssl/include/",
    }
}


@click.command()
@click.option(
    '--platform',
    type=click.Choice(
        ['win', 'mac', 'linux'],
        case_sensitive=True,
    )
)
@click.option('--version')
def generate_patch(platform, version: str):
    diff = Path('pysqlcipher3.diff')

    if diff.exists():
        diff.unlink()

    with open('pysqlcipher3.diff.j2') as f:
        template = Template(f.read())
        openssl_paths = openssl.get(platform)
        lib = openssl_paths.get('lib')
        include = openssl_paths.get('include')

        with open('pysqlcipher3.diff', 'w') as output:
            output.write(
                template.render(
                    version=version,
                    openssl_lib_dir=lib,
                    openssl_include_dir=include,
                )
            )


if __name__ == '__main__':
    generate_patch()
