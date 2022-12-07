# Certificates

Follow the steps mentioned here to generate self signed certificates with openOpenSSLssl.

1. Install [OpenSSL](https://www.openssl.org) in case you don't have it yet

1. Create a separate folder in which the generated files will be placed.

    ```sh
    mkdir mycerts && cd mycerts
    ```

    **Hint:** The folder certs of this repository already exoists and contains the intermediate and a CA certificate. Feel free to use them, i.e. in case you don't want to follow the next steps.

1. Create a file ca.conf in that folder with the content of [certs/ca.conf](https://github.com/nzamani/sap-cloud-connector-docker/blob/master/certs/ca.conf)

    ```sh
    wget https://raw.githubusercontent.com/nzamani/sap-cloud-connector-docker/master/certs/ca.conf
    ```

    **Hint:** ca.conf was created by following step 2 on [Creating Intermediate Certificates](https://help.sap.com/docs/SAP_MOBILE_SERVICES/33c4b62fdc174d89a47d4baee3ced08a/713d30fa7aa346f39896acd1229dc06f.html). However, the config on this site is buggy. The ca.conf as part of this repo is a fixed one.

1. Execute the following commands:

    ```sh
    openssl genrsa -des3 -out SAPCC_CA.key 1024
    # ==> pass phrase for Root_CA.key, i.e.: sapcc

    openssl req -sha256 -new -x509 -days 9999 -key SAPCC_CA.key -out SAPCC_CA.crt
    #==> Choose what ever you want, i.e.:
    # Country Name (2 letter code) []:DE
    # State or Province Name (full name) []:BW
    # Locality Name (eg, city) []:NPL
    # Organization Name (eg, company) []:SAPCC
    # Organizational Unit Name (eg, section) []:SAPCC
    # Common Name (eg, fully qualified host name) []:mysapcc
    # Email Address []:

    openssl pkcs12 -export -clcerts -in SAPCC_CA.crt -inkey SAPCC_CA.key -out SAPCC_CA.p12
    #==> type the password "sapcc" three times (same as above)

    # now intermediate cert:
    touch certindex
    echo 1000 > certserial
    echo 1000 > crlnumber

    # Then use your cli and hit:
    openssl genrsa -out intermediate.key 1024
    openssl req -new -sha256 -key intermediate.key -out intermediate.csr
    openssl ca -batch -config ca.conf -notext -in intermediate.csr -out intermediate.crt
    openssl pkcs12 -export -clcerts -in intermediate.crt -inkey intermediate.key -out intermediate.p12
    ```

    **Hint:** You will ony need the files `intermediate.p12` (for SAPCC) and `SAPCC_CA.crt` (for SAP NW ABAP).
