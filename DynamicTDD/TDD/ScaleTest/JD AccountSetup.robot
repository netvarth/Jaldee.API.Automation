*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Appointment  Waitlist
Library           Collections
Library           OperatingSystem
Library           String
Library           json
Library           random
Library           DateTime
Library           requests
Library           FakerLibrary
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_providers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot
Resource          /ebs/TDD/Keywords.robot



*** Variables ***
@{Views}  self  all  customersOnly
${CAUSERNAME}             admin.support@jaldee.com
${PASSWORD}               Jaldee01
${NEWPASSWORD}            Jaldee12
${SPASSWORD}              Netvarth1
${test_mail}              test@jaldee.com
${count}                  ${1}
${order}        0

*** Test Cases ***

JD-TC-Provider_Signup-1
    [Documentation]   Provider Signup in Random Domain 

    ${data_dir_path}=  Set Variable    ${EXECDIR}/data/${ENVIRONMENT}data/
    ${data_file}=  Set Variable    ${EXECDIR}/data/${ENVIRONMENT}data/${ENVIRONMENT}phnumbers.txt
    ${var_dir_path}=  Set Variable    ${EXECDIR}/data/${ENVIRONMENT}_varfiles/
    ${var_file}=    Set Variable    ${EXECDIR}/data/${ENVIRONMENT}_varfiles/providers.py
    ${data_dir_path1}=  Set Variable    ${EXECDIR}/data/${ENVIRONMENT}data/
    ${var_file1}=    Set Variable    ${EXECDIR}/data/${ENVIRONMENT}_varfiles/usedproviders.py

    IF  ${{os.path.exists($data_dir_path)}} is False
        Create Directory   ${data_dir_path}
    END
    IF  ${{os.path.exists($data_file)}} is False
        Create File   ${data_file}
    END
    IF  ${{os.path.exists($var_dir_path)}} is False
        Create Directory   ${var_dir_path}
    END
    IF  ${{os.path.exists($var_file)}} is False
        Create File   ${var_file}
    END
    IF  ${{os.path.exists($data_dir_path1)}} is False
        Create Directory   ${data_dir_path1}
    END
    IF  ${{os.path.exists($var_file1)}} is False
        Create File   ${var_file1}
    END

    
    ${num}=  find_last  ${var_file}
    ${PUSERPH0}=    Generate Random 555 Number
    FOR  ${index}  IN RANGE   ${count}
        ${num}=  Evaluate   ${num}+1
        ${ph}=  Evaluate   ${PUSERPH0}+${index}
        Log   ${ph}
        # ${ph1}=  Evaluate  ${ph}+1000000000
        # ${ph2}=  Evaluate  ${ph}+2000000000
        # ${licresp}=   Get Licensable Packages
        # Should Be Equal As Strings  ${licresp.status_code}  200
        # # Log   ${licresp.content}
        # ${liclen}=  Get Length  ${licresp.json()}
        # Set Test Variable  ${licpkgid}  ${licresp.json()[0]['pkgId']}
        # Set Test Variable  ${licpkgname}  ${licresp.json()[0]['displayName']}
        ${licpkgid}  ${licpkgname}=  get_highest_license_pkg
        ${corp_resp}=   get_iscorp_subdomains  1
        
        ${resp}=  Get BusinessDomainsConf
        Log   ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        
        ${dom_len}=  Get Length  ${resp.json()}
        ${dom}=  random.randint  ${0}  ${dom_len-1}
        ${sdom_len}=  Get Length  ${resp.json()[${dom}]['subDomains']}
        Set Test Variable  ${domain}  ${resp.json()[${dom}]['domain']}
        Log   ${domain}
        FOR  ${subindex}  IN RANGE  ${sdom_len}
            ${sdom}=  random.randint  ${0}  ${sdom_len-1}
            Set Test Variable  ${subdomain}  ${resp.json()[${dom}]['subDomains'][${subindex}]['subDomain']}
            ${is_corp}=  check_is_corp  ${subdomain}
            Exit For Loop If  '${is_corp}' == 'False'
        END
        Log   ${subdomain}
        
        ${fname}=  FakerLibrary.name
        ${lname}=  FakerLibrary.lastname

        ${resp}=  Account SignUp  ${fname}  ${lname}  ${None}  ${domain}  ${subdomain}  ${ph}   ${licpkgid}
        Log   ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    202

        ${resp}=    Account Activation  ${ph}  ${OtpPurpose['ProviderSignUp']}
        Log   ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200

        ${resp}=  Account Set Credential  ${ph}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${ph}
        Log   ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200

        sleep  03s
        
        ${resp}=  Provider Login  ${ph}  ${PASSWORD}
        Log   ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200

        Append To File  ${data_file}  ${ph} - ${PASSWORD}${\n}
        Append To File  ${var_file}  PUSERNAME${num}=${ph}${\n}
        Append To File  ${var_file1}  PUSERNAME_G=${ph}${\n}
 

        ${resp}=  Get Business Profile
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Test Variable  ${account_id}  ${resp.json()['id']}

        ${fields}=   Get subDomain level Fields  ${domain}  ${subdomain}
        Log  ${fields.content}
        Should Be Equal As Strings    ${fields.status_code}   200

        ${virtual_fields}=  get_Subdomainfields  ${fields.json()}

        ${resp}=  Update Subdomain_Level  ${virtual_fields}  ${subdomain}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200

        ${resp}=  Get specializations Sub Domain  ${domain}  ${subdomain}
        Should Be Equal As Strings    ${resp.status_code}   200

        ${resp}=  Get specializations Sub Domain  ${domain}  ${subdomain}
        Should Be Equal As Strings    ${resp.status_code}   200
        Set Test Variable    ${spec1}     ${resp.json()[0]['displayName']}   
        # Set Test Variable    ${spec2}     ${resp.json()[1]['displayName']}   

        # ${spec}=  Create List    ${spec1}   ${spec2}
        ${spec}=  Create List    ${spec1}   
        ${resp}=  Update Business Profile with kwargs  specialization=${spec}  
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200


    

    ${resp}=  Toggle Department Enable
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    sleep  2s
    ${resp}=  Get Departments
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${dep_id}  ${resp.json()['departments'][0]['departmentId']}
     
    ${resp}=  View Waitlist Settings
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Run Keyword If  ${resp.json()['filterByDept']}==${bool[0]}   Toggle Department Enable
    Run Keyword If  '${resp}' != '${None}'   Log   ${resp.json()}
    Run Keyword If  '${resp}' != '${None}'   Should Be Equal As Strings  ${resp.status_code}  200

    ${lid}=  Create Sample Location

    ${resp}=    Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${accountId}        ${resp.json()['id']}

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    IF  ${resp.json()['enableInventory']}==${bool[0]}
        ${resp1}=  Enable Disable Inventory  ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200

        ${resp}=  Get Account Settings
        Log  ${resp.json()}
        Should Be Equal As Strings  ${resp.status_code}  200
        Should Be Equal As Strings  ${resp.json()['enableInventory']}  ${bool[1]}
    END

    IF  ${resp.json()['enableSalesOrder']}==${bool[0]}
        ${resp1}=  Enable/Disable SalesOrder  ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200

        ${resp}=  Get Account Settings
        Log  ${resp.json()}
        Should Be Equal As Strings  ${resp.status_code}  200
        Should Be Equal As Strings  ${resp.json()['enableSalesOrder']}  ${bool[1]}
    END

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[0]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[1]}

    ${resp}=  Get Store Type By Filter     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
# --------------------- Create Store Type from sa side -------------------------------
    ${TypeName}=    FakerLibrary.name
    Set Suite Variable  ${TypeName}
    sleep  02s

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}

    ${resp}=  Get Store Type By EncId   ${St_Id}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}
# --------------------- ---------------------------------------------------------------

    ${resp}=  Encrypted Provider Login  ${PUSERNAME_G}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${accountId}=  get_acc_id  ${HLPUSERNAME16}
    # Set Suite Variable    ${accountId} 

    ${resp}=  Provide Get Store Type By EncId     ${St_Id}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${locId1}=  Create Sample Location
        ${resp}=   Get Location ById  ${locId1}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Suite Variable  ${tz}  ${resp.json()['bSchedule']['timespec'][0]['timezone']}
    ELSE
        Set Suite Variable  ${locId1}  ${resp.json()[0]['id']}
        Set Suite Variable  ${tz}  ${resp.json()[0]['bSchedule']['timespec'][0]['timezone']}
    END

    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    Set Suite Variable  ${address}
    Set Suite Variable  ${postcode}
    Set Suite Variable  ${city}

# ------------------------ Create Store ----------------------------------------------------------

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY1} 

    ${Store_Name1}=    FakerLibrary.first name
    Set Suite Variable  ${Store_Name1}
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Suite Variable  ${email_id}  ${Store_Name1}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Store_Name1}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}


# ----------------------------------------- create Inv Catalog -------------------------------------------------------
    ${INV_Cat_Name}=     FakerLibrary.name

    ${resp}=  Create Inventory Catalog   ${INV_Cat_Name}  ${store_id}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${Catalog_EncIds}  ${resp.json()}


# ----------------------------------------- create sales order Catalog -------------------------------------------------------
    ${Store_name}=  FakerLibrary.name
    Set Suite Variable    ${Store_name}
    ${inv_cat_encid_List}=  Create List  ${Catalog_EncIds}
    ${price}=    Random Int  min=2   max=40
    ${price}=  Convert To Number  ${price}    1

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr True   ${store_id}  ${Store_name}  ${boolean[1]}  ${inv_cat_encid_List}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${inv_order_encid}  ${resp.json()}



    END