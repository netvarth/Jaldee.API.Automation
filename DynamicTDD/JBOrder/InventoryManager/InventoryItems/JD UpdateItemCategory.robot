*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        ITEM 
Library           Collections
Library           String
Library           json
Library           DateTime
Library           requests
Library           FakerLibrary
Library           /ebs/TDD/CustomKeywords.py
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/Keywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_providers.py

*** Test Cases ***

JD-TC-UpdateItemCategory-1

    [Documentation]  Provider Create a Item Category then try to Update that item name.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    IF  ${resp.json()['enableInventory']}==${bool[0]}
        ${resp1}=  Enable Disable Inventory  ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${categoryName}=    FakerLibrary.name
    Set Suite Variable  ${categoryName}

    ${resp}=  Create Item Category   ${categoryName}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${Ca_Id}    ${resp.json()}

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${categoryName1}=    FakerLibrary.name
    Set Suite Variable  ${categoryName1}


    ${resp}=  Update Item Category   ${categoryName1}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['categoryCode']}    ${Ca_Id}
    Should Be Equal As Strings    ${resp.json()['categoryName']}    ${categoryName1}
    Should Be Equal As Strings    ${resp.json()['status']}    ${toggle[0]}


JD-TC-UpdateItemCategory-2

    [Documentation]  Update item CategoryName to a Number.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name1}=    FakerLibrary.Random Number

    ${resp}=  Update Item Category   ${Name1}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['categoryName']}    ${Name1}



JD-TC-UpdateItemCategory-3

    [Documentation]  Update item CategoryName then update it's Item Category Status.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.name

    ${resp}=  Update Item Category   ${Name}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200



    ${resp}=  Update Item Category Status   ${Ca_Id}    ${toggle[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 
    Should Be Equal As Strings    ${resp.json()['status']}    ${toggle[1]} 



JD-TC-UpdateItemCategory-4

    [Documentation]  Try to Update Disable item  .

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.name

    ${resp}=  Update Item Category   ${Name}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 
    Should Be Equal As Strings    ${resp.json()['categoryName']}    ${Name}




JD-TC-UpdateItemCategory-5

    [Documentation]  Update item Category name as same.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Update Item Category   ${categoryName1}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Category   ${Ca_Id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UpdateItemCategory-UH3

    [Documentation]  Update item CategoryName With EMPTY value.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${Name1}=    FakerLibrary.Random Number

    ${resp}=  Update Item Category   ${EMPTY}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${INVALID_CATEGORY_NAME} 
    

JD-TC-UpdateItemCategory-UH1

    [Documentation]  Get Item Category without Login.

    ${resp}=  Update Item Category   ${EMPTY}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    419
    Should Be Equal As Strings    ${resp.json()}    ${SESSION_EXPIRED} 

JD-TC-UpdateItemCategory-UH2

    [Documentation]  Get Item Category with Consumer Login.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME36}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${accountId}        ${resp.json()['id']}

     ${firstname}=  generate_firstname
    ${lastname}=  FakerLibrary.last_name
    ${PH_Number}=  FakerLibrary.Numerify  %#####
    ${PUSERNAME_N}=  Evaluate  ${PUSERNAME}+${PH_Number}
    Set Suite Variable    ${PUSERNAME_N}
    Set sUITE Variable  ${email}  ${firstname}${PUSERNAME_N}${C_Email}.${test_mail}


    ${resp}=    Send Otp For Login    ${PUSERNAME_N}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${PUSERNAME_N}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${tokenss}  ${resp.json()['token']}

    ${resp}=    Consumer Logout
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}  ${PUSERNAME_N}  ${accountId}  Authorization=${tokenss}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200    

    ${resp}=    ProviderConsumer Login with token   ${PUSERNAME_N}  ${accountId}  ${tokenss} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200



    ${resp}=  Update Item Category   ${EMPTY}    ${Ca_Id}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    401
    Should Be Equal As Strings    ${resp.json()}    ${NoAccess} 
