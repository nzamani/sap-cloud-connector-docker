# SAPCP Identity Provisioning Service

This documentastion descripes how to easily setup the SAPCP Identity Provisioning Sertvice (IPS) for making
NW ABAP Users available in a given SAPCP account while they are assigned to a certain Group in SAPCP. This can be seamlessly used to configure which SAP FLP Catalogs/Groups (Portzal Service) are available for a given user.

See [SAPCP Identity Provisioning Service on SAP HELP](https://help.sap.com/viewer/p/IDENTITY_PROVISIONING) for additional details.

**Hint:** Most of the steps here are well documented [here](https://help.sap.com/viewer/f48e822d6d484fa5ade7dda78b64d9f5/Cloud/en-US/5235087c8a6e4860aac36a8c3675fb9d.html).

## SAPCC Configuration

1. Createn an RFC Mapping in SAPCC

     Follow [this](https://help.sap.com/viewer/f48e822d6d484fa5ade7dda78b64d9f5/Cloud/en-US/5235087c8a6e4860aac36a8c3675fb9d.html) SAPCP Identity Provisioning Service documentation on SAP HELP or simply import the file [sapcc_access_control_rfc_only.json](./sapcc_access_control_rfc_only.json) into your SAP Cloud Connector's Accecc Control Mapping. Before you import check the content of the file and adjust it to your needs.

    **Hint:** The SAPCP Trial account only allows 2 active Mappings! In case you add more than two mappings it seems the connection from SAPCC to SAPCP is closed by SAPCP. In that case you have to delete your mappings so that you have at max. 2 mappings. Then you can reconnect your SAPCC to SAPCP account from within SAPCC.

## NW ABAP Configuration

1. Create technical/service user in SU01

    - User ID (for example): `ZSSAPCPIPS`

    **Hint:** Make sure this user is a `Service User` and assign an initial password, i.e. `Appl1ance`

1. PFCG: SAP_BC_JSF_COMMUNICATION_RO

    In transaction `PFCG` go to role `SAP_BC_JSF_COMMUNICATION_RO`, then:

    - generate profile
    - assign user `ZSSAPCPIPS` to the role

1. PFCG: Create Role `ZS_RFC_SAPCPIPS` with Authorization Objects:

    - **S_RFC**
      - RFC_TYPE: Function group, Function Module
      - RFC_NAME:

          ```sh
          BAPI_USER
          BAPI_USER_GETLIST
          BAPI_USER_GET_DETAIL
          PRGN_ROLE_GETLIST
          PRNG
          ```
      - ACTVT: Execute

    - **S_USER_AGR**
      - ACT_GROUP: DUMMY
      - ACTVT: Display

    These two Authorization Objects are not mentioned in the [official documentation](https://help.sap.com/viewer/f48e822d6d484fa5ade7dda78b64d9f5/Cloud/en-US/5235087c8a6e4860aac36a8c3675fb9d.html) mentioned above:

    - **S_RFC** is needed because the IPS will call RFCs, thus the service user needs RFC authorization

    - **S_USER_AGR** is needed because the function module `PRGN_ROLE_GETLIST` does the following in the very beginning:

        ```sh
        authority-check object 'S_USER_AGR'
            id 'ACT_GROUP' dummy
            id 'ACTVT' field '03'.
        ```

1. PFCG: Create additional roles for demonstration of IPS
    - ZDEMO_MANAGER
    - ZDEMO_PURCHASER
    - ZDEMO_SALESREP

1. SU01: Create Users with roles for demonstration of IPS
    - SALESREP
      - Roles: ZDEMO_SALESREP
    - PURCHASER
      - Roles: ZDEMO_PURCHASER
    - MANAGER
      - Roles: ZDEMO_MANAGER, ZDEMO_PURCHASER

1. Assign roles to your own SAP user
    - ZDEMO_MANAGER
    - ZDEMO_PURCHASER
    - ZDEMO_SALESREP

## SAP Cloud Platform Configuration

1. OAuth Client Credentials in Target SAPCP account (i.e. Trial)

    - Go to **Security** -> **OAuth** -> **Platform API** and press **Create API Client**
    - In the dialog
      - set a description (i.e. "Identity Provisioning Service")
      - check **Authorization Management** (will add **Read Authorization** and **Manage Authorization** automatically)
      - then press "save"

    **Important**: Make sure to save the generated OAuth Client Credentials (both Client ID and Client Secret)

1. SAPCP Destinations (on SAPCP account level, for me it did not work as expected IPS level)

    - RFC Destination (NW ABAP)

      | Field          | Value                                       |
      |:-------------- |:------------------------------------------- |
      | Name           | IPS_SOURCE_NPL_001_RFC                      |
      | Type           | RFC                                         |
      | Description    | IPS Read from NPL in Docker (NW ABAP Trial) |
      | Location ID    |                                             |
      | User           | ZSSAPCPIPS                                  |
      | Password       | Appl1ance                                   |

      **Properties**

      | Property           | Value     |
      |:-------------------|:----------|
      | jco.client.ashost  | nwabap751 |
      | jco.client.client  | 001       |
      | jco.client.r3name  | NPL       |
      | jco.client.sysnr   | 00        |

    - HTTP Destination (SAPCP account, in our case to the trial account)

      Now [create the destination](https://help.sap.com/viewer/f48e822d6d484fa5ade7dda78b64d9f5/Cloud/en-US/dcdf72892190449384ba522fa95b4e8e.html) using the generated OAuth Client Credentials:

      | Field          | Value                                                                     |
      |:-------------- |:------------------------------------------------------------------------- |
      | Name           | IPS_TARGET_MYTRIAL_SAPCP                                                  |
      | Type           | HTTP                                                                      |
      | Description    | IPS Target to My SAPCP Trial                                              |
      | URL            | [https://api.hanatrial.ondemand.com/authorization/v1/accounts/p123456trial](https://api.hanatrial.ondemand.com/authorization/v1/accounts/p123456trial) |
      | Proxy Type     | Internet                                                                  |
      | Authentication | BasicAuthentication                                                       |
      | User           | Client ID                                                                 |
      | Password       | Client Secret                                                             |

      **Properties**

      | Property              | Value                                             |
      |:----------------------|:--------------------------------------------------|
      | OAuth2TokenServiceURL | [https://api.hanatrial.ondemand.com/oauth2/apitoken/v1](https://api.hanatrial.ondemand.com/oauth2/apitoken/v1) |

      Also make sure to check "Use default JDK truststore".

1. SAPCP Identity Provision Service (IPS)

    - Add Source System

      - Details

        | Field            | Value                          |
        |:---------------- |:------------------------------ |
        | Type             | SAP Applicaiton Server ABAP    |
        | System Name      | NW-ABAP-751-NPL                |
        | Destination Name | IPS_SOURCE_NPL_001_RFC         |
        | Description      | NW ABAP 7.51 Trial in Docker   |

      - Transformation
        Use the content of [NW-ABAP-751-NPL-001.source.transformation.json](./NW-ABAP-751-NPL-001.source.transformation.json)

      - Properties
        - `abap.role.filter`: `^(YDEMO|ZDEMO).*`
        - `ips.trace.failed.entity.content`: `true`

    - Add Target System

      - Details

        | Field            | Value                              |
        |:---------------- |:---------------------------------- |
        | Type             | SAP Cloud Platform Java/HTML5 Apps |
        | System Name      | SAPCP-MyTrial                      |
        | Destination Name | IPS_TARGET_MYTRIAL_SAPCP           |
        | Description      | Trial SAPCP Account                |

      - Transformation
        Use the content of [SAPCP-MyTrial.target.transformation.json](./SAPCP-MyTrial.target.transformation.json)

      - Properties
        - `ips.trace.failed.entity.content`: `true`

    - Run the `Read Job` from your Source System + check result in log etc.
