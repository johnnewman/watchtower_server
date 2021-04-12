"""
This module will start a unix socket server and listen for messages. This is
used to pass messages out of a Docker container into the host level. When
messaged, the nginx templates will be updated and nginx will be restarted.
"""

import asyncio
import atexit
import logging
import os
import subprocess


socket_path = os.environ['SOCKET_PATH']
gid = int(os.environ['SOCKET_GID'])
template_command = 'new template'
terminator = b'[close]'

async def handle_command(reader, writer):

    async def send_response(message):
        writer.write(message.encode())
        await writer.drain()
        writer.close()

    data = await reader.readline()
    message = data.decode().rstrip()
    if message == template_command:

        # Read the full template document from the socket.
        document = await reader.readuntil(terminator)
        document = document[:-7]

        main_template = 'nginx/templates/default.conf.template'
        backup_template = main_template + '.BAK'
        if os.path.exists(backup_template):
            logging.getLogger(__name__).info('Removing old backup template.')
            os.remove(backup_template)

        if os.path.exists(main_template):
            logging.getLogger(__name__).info('Backing up current template.')
            os.rename(main_template, backup_template)

        with open(main_template, 'wb') as out_file:
            out_file.write(document)

        logging.getLogger(__name__).info('Restarting nginx...')
        subprocess.run(['docker-compose', 'restart', 'server'])
        await send_response('ok')

    else:
        await send_response('error')
        logging.getLogger(__name__).warn('Unknown command %s' % message)

async def wait_for_commands():
    
    server = await asyncio.start_unix_server(
        handle_command,
        socket_path,
    )
    # Once created, set the permissions on the socket to the minimum required.
    os.chmod(socket_path, 0o660)
    os.chown(socket_path, -1, gid)

    logging.getLogger(__name__).info(f'Listening on {socket_path}')
    async with server:
        await server.serve_forever()

def shutdown():
    logging.getLogger(__name__).info(f'Shutting down. Deleting socket at {socket_path}.')
    os.remove(socket_path)
    
atexit.register(shutdown)
logging.basicConfig(level=logging.INFO, format='%(message)s')
asyncio.run(wait_for_commands())
