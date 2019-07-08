#!/usr/bin/env python

import sys, json
import os
import socket
import paramiko

def create_sftp_client(host, port, username, password, keyfilepath, keyfiletype, usessh):
    """
    create_sftp_client(host, port, username, password, keyfilepath, keyfiletype) -> SFTPClient

    Creates a SFTP client connected to the supplied host on the supplied port authenticating as the user with
    supplied username and supplied password or with the private key in a file with the supplied path.
    If a private key is used for authentication, the type of the keyfile needs to be specified as DSA or RSA.
    :rtype: SFTPClient object.
    """
    ssh = None
    sftp = None
    key = None
    transport = None
    try:
        if keyfilepath is not None:
            # Get private key used to authenticate user.
            if keyfiletype == 'DSA':
                # The private key is a DSA type key.
                key = paramiko.DSSKey.from_private_key_file(keyfilepath)
            else:
                # The private key is a RSA type key.
                key = paramiko.RSAKey.from_private_key_file(keyfilepath)

        print ('retrieved key')
        if usessh:
            # Connect SSH client accepting all host keys.
            ssh = paramiko.SSHClient()
            print ('SSHClient created')
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(host, port, username, password, key)
            print ('connected')

            # Using the SSH client, create a SFTP client.
            sftp = ssh.open_sftp()
            # Keep a reference to the SSH client in the SFTP client as to prevent the former from
            # being garbage collected and the connection from being closed.
            sftp.sshclient = ssh
        else:
            # Create Transport object using supplied method of authentication.
            transport = paramiko.Transport((host, port))
            print ('transport created')
            transport.connect(None, username, password, key)

            print ('connected')
            sftp = paramiko.SFTPClient.from_transport(transport)

        return sftp
    except Exception as e:
        print('An error occurred creating SFTP client: {}: {}'.format(e.__class__, e))
        if sftp is not None:
            sftp.close()
        if transport is not None:
            transport.close()
        if ssh is not None:
            ssh.close()
        pass

# arguments:
#    3. subfolder of file in HOST:DIRN
#    4. local folder for file
#    5. filename target

def main(argv):
    print ('{}:{}:{}:{}:{}:{}'.format(sys.argv[0],sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5]))
    HOST = sys.argv[1]
    DIRN = sys.argv[2]
    qatestpath = sys.argv[3]
    localdir = sys.argv[4]
    targetname = sys.argv[5]
    buildsys = 'build'
    script_path, script_name = os.path.split(sys.argv[0])

    script_res = {script_name: 'SUCCESS'}

    scriptdir=os.getcwd() ####
    print(os.listdir('.'))
    print('scriptdir='+scriptdir)
    print(os.listdir('..'))

    jsparams_file = '../bb_params.json'
    if scriptdir.split(os.sep)[-1] == buildsys:
        jsparams_file = 'bb_params.json'

    if os.path.exists(jsparams_file):
        with open(jsparams_file, 'r') as json_bbparams_file:
            json_bbparams_data = json.load(json_bbparams_file)
    else:
        json_bbparams_data = []
    print(json_bbparams_data)

    thereturncode = 0
    sftpclient = create_sftp_client(HOST, 22, 'hdftest', None, os.path.expanduser(os.path.join("~", ".ssh", "bitbidkey")), 'RSA', True)
    if sftpclient is not None:
        try:
            sftpclient.chdir(DIRN + '%s' % qatestpath)
        except Exception as e:
            thereturncode = 255
            print ('ERROR: cannot CD to "{}{}"'.format(DIRN,qatestpath))
            if sftpclient is not None:
                sftpclient.close()
        print ('*** Changed to folder: "{}{}"'.format(DIRN,qatestpath))

        currdir=os.getcwd() ####

        try:
            if not os.path.exists('%s' % localdir):
                os.mkdir('%s' % localdir)
            os.chdir('%s' % localdir)
            filename = '%s' % targetname
            print ('Getting {}'.format(filename))
            sftpclient.get(filename, filename)
            print ('File {} downloaded'.format(filename))
        except Exception as e:
            thereturncode = 255
            print ('ERROR: cannot read file {}'.format(filename))

        os.chdir(currdir) ####
        sftpclient.close()
    if thereturncode != 0:
        script_res = {script_name: 'FAILURE'}
        json_bbparams_data.append(script_res)
        with open(jsparams_file, 'w') as json_bbparams_file:
            json.dump(json_bbparams_data, json_bbparams_file)
        raise Exception('Unable to download file')

    os.chdir(scriptdir) ####
    json_bbparams_data.append(script_res)
    with open(jsparams_file, 'w') as json_bbparams_file:
        json.dump(json_bbparams_data, json_bbparams_file)
    return thereturncode

if __name__ == '__main__':
    main(sys.argv)

