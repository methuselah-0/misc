set -e

installDependencies(){
    apt-get install gcc make python-zbar libltdl-dev libsqlite3-dev libunistring-dev libopus-dev libpulse-dev openssl libglpk-dev texlive libidn11-dev libmysqlclient-dev libpq-dev libarchive-dev libbz2-dev libflac-dev libgif-dev libglib2.0-dev libgtk-3-dev libmpeg2-4-dev libtidy-dev libvorbis-dev libogg-dev zlib1g-dev g++ gettext libgsf-1-dev libunbound-dev libqrencode-dev libgladeui-dev nasm texlive-latex-extra libunique-3.0-dev gawk miniupnpc libfuse-dev libbluetooth-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good libgstreamer-plugins-base1.0-dev nettle-dev libextractor-dev libgcrypt20-dev libmicrohttpd-dev sqlite3
    wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.12.tar.xz
    wget https://gnunet.org/sites/default/files/gnurl-7.40.0.tar.bz2
    tar xvf gnutls-3.3.12.tar.xz
    tar xvf gnurl-7.40.0.tar.bz2
    cd gnutls-3.3.12 ; ./configure ; make ; make install ; cd ..
    cd gnurl-7.40.0
    ./configure --enable-ipv6 --with-gnutls=/usr/local --without-libssh2 --without-libmetalink --without-winidn --without-librtmp --without-nghttp2 --without-nss --without-cyassl --without-polarssl --without-ssl --without-winssl --without-darwinssl --disable-sspi --disable-ntlm-wb --disable-ldap --disable-rtsp --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-file --disable-ftp --disable-smb
    make ; make install; cd ..
}
addUser(){
    adduser --system --home /var/lib/gnunet --group --disabled-password gnunet
    addgroup --system gnunetdns
}

install(){
    git clone https://gnunet.org/git/gnunet.git/
    cd gnunet
    ./bootstrap
    ./configure --with-sudo=sudo --with-nssdir=/lib
    make
    make install
    # You may need to update your ld.so cache to include files installed in /usr/local/lib:    
    ldconfig
}

createConf(){
cat <<EOF > /etc/gnunet.conf
[arm]
SYSTEM_ONLY = YES
USER_ONLY = NO
EOF
}
userConf(){
cat <<EOF > /home/$username/.config/gnunet.conf
[arm]
SYSTEM_ONLY = YES
USER_ONLY = NO
EOF
}

main(){
    installDependencies
    addUser
    install
    createConf
    sudo -u gnunet /bin/bash -c gnunet-arm -c /etc/gnunet.conf -s &
}
main
echo "To allow more than user gnunet to use the services run \"adduser \$some_user gnunet\"."
echo "You have to logout and login again for that to take effect."
echo "You can start and stop your GNUnet with:"
echo "Start:
echo "su -s /bin/bash - gnunet"
echo "gnunet-arm -c /etc/gnunet.conf -s &"
echo "Stop:"
echo "gnunet-arm -e"
