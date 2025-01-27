*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        STORE 
Library           Collections
Library           String
Library           json
Library           DateTime
Library           requests
Library           FakerLibrary
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/Keywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_providers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot

*** Variables ***
${invalidNum}        1245
${invalidEma}        asd122
${invalidstring}     _ad$.sa_


*** Test Cases ***

JD-TC-Create SalesOrder Inventory Catalog-1
    [Documentation]  create sales order inventory catalog with valid details.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Store Type By Filter     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${TypeName}=    FakerLibrary.name
    Set Suite Variable  ${TypeName}

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}
    sleep  02s
    ${TypeName1}=    FakerLibrary.name
    Set Suite Variable  ${TypeName1}

    ${resp}=  Create Store Type   ${TypeName1}    ${storeNature[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id1}    ${resp.json()}
    sleep  02s
    ${TypeName2}=    FakerLibrary.name
    Set Suite Variable  ${TypeName2}

    ${resp}=  Create Store Type   ${TypeName2}    ${storeNature[2]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id2}    ${resp.json()}

    ${resp}=  Get Store Type By EncId   ${St_Id}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    # Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    # Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=  get_acc_id  ${HLPUSERNAME40}
    Set Suite Variable    ${accountId} 

    ${resp}=  Provider Get Store Type By EncId     ${St_Id}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    # Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    # Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${locId1}=  Create Sample Location
        ${resp}=   Get Location ById  ${locId1}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Suite Variable  ${tz}  ${resp.json()['timezone']}
    ELSE
        Set Suite Variable  ${locId1}  ${resp.json()[0]['id']}
        Set Suite Variable  ${tz}  ${resp.json()[0]['timezone']}
    END

    ${Name}=    FakerLibrary.last name
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Name}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id}   ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-2
    [Documentation]  create multiple sales order inventory catalog with same store id.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False    ${store_id}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-3
    [Documentation]  create sales order inventory catalog using store nature as lab.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.last name
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Name}  ${St_Id1}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id1}  ${resp.json()}

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False    ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-4
    [Documentation]  create  sales order inventory catalog where name as number.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False    ${store_id1}   ${invalidNum}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-5
    [Documentation]  create  sales order inventory catalog where name as invalid string.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${invalidstring}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-6
    [Documentation]  create sales order inventory catalog with same  name with different store id.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Create SalesOrder Inventory Catalog-7
    [Documentation]  create sales order inventory catalog from main account then create sales order catalog with same name from user login(without admin privilege).(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.last name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable  ${encid}  ${resp.json()}


    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    IF  ${resp.json()['filterByDept']}==${bool[0]}
        ${resp}=  Enable Disable Department  ${toggle[0]}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200

    END

    ${dep_name1}=  FakerLibrary.bs
    ${dep_code1}=   Random Int  min=100   max=999
    ${dep_desc1}=   FakerLibrary.word   
        ${resp1}=  Create Department  ${dep_name1}  ${dep_code1}  ${dep_desc1} 
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
        Set Test Variable  ${dep_id}  ${resp1.json()}



     
    FOR  ${p}  IN RANGE  5
        ${ran int}=    Generate Random String    length=4    chars=[NUMBERS]
        ${ran int}=    Convert To Integer    ${ran int}
        ${ran int}=    Convert To Integer    ${ran int}
        ${ran int}=    Convert To String  ${ran int}
        ${Status}=   Run Keyword And Return Status   Should Match Regexp	${ran int}	\\d{4}
        Exit For Loop IF  ${Status}  
    END
    ${ran int}=    Convert To Integer    ${ran int}
    ${PUSERNAME_U1}=  Evaluate  ${PUSERNAME}+${ran int}
    Set Test Variable  ${PUSERNAME_U1}
    clear_users  ${PUSERNAME_U1}
    ${firstname1}=  FakerLibrary.name
    Set Test Variable  ${firstname1}
    ${lastname1}=  FakerLibrary.last_name
    Set Test Variable  ${lastname1}
    ${dob1}=  FakerLibrary.Date
    Set Test Variable  ${dob1}
    ${pin1}=  get_pincode
    Set Test Variable  ${pin1}

    # ${so_id1}=  Create Sample User   deptId=${dep_id} 
    # Set Suite Variable  ${u_id1}

    # ${resp}=  Create User  ${firstname1}  ${lastname1}  ${dob1}  ${Genderlist[0]}  ${P_Email}${PUSERNAME_U1}.${test_mail}   ${userType[0]}  ${pin1}  ${countryCodes[0]}  ${PUSERNAME_U1}  ${dep_id}  ${EMPTY}  ${bool[0]}  ${NULL}  ${NULL}  ${NULL}  ${NULL}
    # Log   ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable  ${u_id1}  ${resp.json()}


    # ${resp}=  Get User By Id  ${u_id1}
    # Log   ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200


    # ${resp}=  SendProviderResetMail   ${PUSERNAME_U1}
    # Should Be Equal As Strings  ${resp.status_code}  200

    # @{resp}=  ResetProviderPassword  ${PUSERNAME_U1}  ${PASSWORD}  ${OtpPurpose['ProviderResetPassword']}
    # Should Be Equal As Strings  ${resp[0].status_code}  200
    # Should Be Equal As Strings  ${resp[1].status_code}  200


    ${PUSERNAME_U1}  ${u_id1} =  Create and Configure Sample User   deptId=${dep_id}  

    ${resp}=    Provider Logout
    Should Be Equal As Strings  ${resp.status_code}    200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME_U1}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}   200


    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${ORDER_CATALOG_EXIST_WITH_THE_GIVEN_NAME}

# JD-TC-Create SalesOrder Inventory Catalog-8

#     [Documentation]  create  sales order catalog where name as invalid string.(inventory manager is true)

#     ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200

#     ${Name}=    FakerLibrary.first name
#     ${resp}=  Create Inventory Catalog   ${Name}  ${store_id1}   
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Test Variable  ${inv_cat_encid}  ${resp.json()}
#     ${inv_cat_encid}=  Create List  ${inv_cat_encid}

#     ${resp}=  Create SalesOrder Inventory Catalog-InvMgr True   ${store_id1}  ${invalidstring}  ${boolean[1]}  ${inv_cat_encid}
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200


JD-TC-Create SalesOrder Inventory Catalog-UH1
    [Documentation]  create sales order inventory catalog with empty name.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${EMPTY}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${MEMBER_SERVICE_NAME_REQUIRED}
    

JD-TC-Create SalesOrder Inventory Catalog-UH2
    [Documentation]  create sales order inventory catalog with invalid store id.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${Name}  ${Name}  ${boolean[0]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${INVALID_STORE_ID}


JD-TC-Create SalesOrder Inventory Catalog-UH3
    [Documentation]  create sales odrer inventory catalog without login.(inventory manager is false)

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}


JD-TC-Create SalesOrder Inventory Catalog-UH4
    [Documentation]  create sales order inventory catalog using sa login.(inventory manager is false)

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Name}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}


JD-TC-Create SalesOrder Inventory Catalog-UH5
    [Documentation]  create  sales order inventory catalog where name length is <1.(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Text}=  FakerLibrary.Sentence   nb_words=-1
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Text}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${MEMBER_SERVICE_NAME_REQUIRED}


JD-TC-Create SalesOrder Inventory Catalog-UH6
    [Documentation]  create sales order inventory catalog where name(STRING length is 256).(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Text}=  Generate Random String  256
    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${Text}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${NAME_LENGT_TOO_LONG}


JD-TC-Create SalesOrder Inventory Catalog-UH7
    [Documentation]  create  sales orderinventory catalog with same name .(inventory manager is false)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}  ${invalidstring}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${ORDER_CATALOG_EXIST_WITH_THE_GIVEN_NAME}

JD-TC-Create SalesOrder Inventory Catalog-UH8
    [Documentation]  create  sales order catalog then try to disable inventory catalog

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME40}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create Inventory Catalog   ${Name}  ${store_id1}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable  ${inv_cat_encid1}  ${resp.json()}
    ${inv_cat_encid}=  Create List  ${inv_cat_encid1}

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr True   ${store_id1}  ${Name}  ${boolean[1]}  ${inv_cat_encid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Update Inventory Catalog status   ${inv_cat_encid1}  ${InventoryCatalogStatus[1]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings   ${resp.json()}   ${INVENTORY_CATALOG_CONNECTED_TO_ORDER_CATALOG}
    
    



