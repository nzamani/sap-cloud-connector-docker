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

1. PFCG: Create Role `ZS_RFC_SAPCPIPS`

**Authorization Objects:**

- **S_RFC**
  - FRC_TYPE: Function group, Function Module
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

1. SAPCP Destinations
- NW ABAP
- SAPCP Trial

1. SAPCP IPS
- enable + go to service

- Create Source System
  - Properties
    - `abap.role.filter`: `^(YDEMO|ZDEMO).*`
    - `ips.trace.failed.entity.content`: `true`

- Create Target System

- Start Sync
