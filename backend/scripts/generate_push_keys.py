"""Generate local VAPID keys without printing or overwriting the private key."""
import argparse
import base64
import os
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output-dir', default='private-push')
    args = parser.parse_args()
    directory = Path(args.output_dir)
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = directory / 'vapid_private.pem'
    private = ec.generate_private_key(ec.SECP256R1())
    pem = private.private_bytes(serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
    # O_EXCL prevents rotating an existing installation accidentally.
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as file:
        file.write(pem)
    public = private.public_key().public_bytes(serialization.Encoding.X962,
        serialization.PublicFormat.UncompressedPoint)
    print('VAPID_PUBLIC_KEY=' + base64.urlsafe_b64encode(public).decode().rstrip('='))
    print('VAPID_PRIVATE_KEY=' + str(path.resolve()))


if __name__ == '__main__':
    main()
