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
Variables         /ebs/TDD/varfiles/hl_musers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot

*** Variables ***
${invalidNum}        1245
${invalidEma}        asd122

*** Keywords ***
Create Store

    [Arguments]  ${name}   ${storeTypeEncId}  ${locationId}  ${emails}  ${number}  ${countryCode}  
    ${phoneNumber}=  Create Dictionary  number=${number}    countryCode=${countryCode} 
    ${phoneNumbers}=  Create List  ${phoneNumber}
    ${data}=  Create Dictionary  name=${name}   storeTypeEncId=${storeTypeEncId}    locationId=${locationId}    emails=${emails}    phoneNumbers=${phoneNumbers}    
    ${data}=  json.dumps  ${data}
    Check And Create YNW Session
    ${resp}=  POST On Session  ynw  /provider/store   data=${data}  expected_status=any
    RETURN  ${resp} 

Get Store ByEncId
    [Arguments]   ${Encid}
    Check And Create YNW Session
    ${resp}=    GET On Session    ynw   /provider/store/${Encid}      expected_status=any
    RETURN  ${resp}

Update Store

    [Arguments]     ${store_id}   ${name}   ${storeTypeEncId}  ${locationId}  ${emails}  ${number}  ${countryCode}  
    ${phoneNumber}=  Create Dictionary  number=${number}    countryCode=${countryCode} 
    ${phoneNumbers}=  Create List  ${phoneNumber}
    ${data}=  Create Dictionary  name=${name}   storeTypeEncId=${storeTypeEncId}    locationId=${locationId}    emails=${emails}    phoneNumbers=${phoneNumbers}    
    ${data}=  json.dumps  ${data}
    Check And Create YNW Session
    ${resp}=  PUT On Session  ynw  /provider/store/${store_id}    data=${data}  expected_status=any
    RETURN  ${resp} 

*** Test Cases ***

JD-TC-UpdateStore-1

    [Documentation]  Service Provider Create a store with valid details(store type is PHARMACY)then Update it's name.

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${TypeName}=    FakerLibrary.name
    Set Suite Variable  ${TypeName}

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}

    ${TypeName1}=    FakerLibrary.name
    Set Suite Variable  ${TypeName1}

    ${resp}=  Create Store Type   ${TypeName1}    ${storeNature[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id1}    ${resp.json()}

    ${TypeName2}=    FakerLibrary.name
    Set Suite Variable  ${TypeName2}

    ${resp}=  Create Store Type   ${TypeName2}    ${storeNature[2]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id2}    ${resp.json()}

    ${resp}=  Get Store Type By EncId   ${St_Id}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME1}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=  get_acc_id  ${HLMUSERNAME1}
    Set Suite Variable    ${accountId} 

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

    ${Name}=    FakerLibrary.last name
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Name}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}

    ${resp}=    Get Store ByEncId   ${store_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['accountId']}  ${accountId}
    Should Be Equal As Strings  ${resp.json()['locationId']}  ${locId1}
    Should Be Equal As Strings  ${resp.json()['name']}  ${Name}
    Should Be Equal As Strings  ${resp.json()['storeTypeEncId']}  ${St_Id}
    Should Be Equal As Strings  ${resp.json()['onlineOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['walkinOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['partnerOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['encId']}  ${store_id}
    Should Be Equal As Strings  ${resp.json()['storeNature']}  ${storeNature[0]}
    Should Be Equal As Strings  ${resp.json()['phoneNumbers'][0]['number']}  ${PhoneNumber}
    Should Be Equal As Strings  ${resp.json()['phoneNumbers'][0]['countryCode']}  ${countryCodes[0]}
    Should Be Equal As Strings  ${resp.json()['emails'][0]}  ${email_id}

    ${Name1}=    FakerLibrary.last name

    ${resp}=  Update Store      ${store_id}    ${Name1}  ${St_Id}    ${locId1}   ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Get Store ByEncId   ${store_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['accountId']}  ${accountId}
    Should Be Equal As Strings  ${resp.json()['locationId']}  ${locId1}
    Should Be Equal As Strings  ${resp.json()['name']}  ${Name1}
    Should Be Equal As Strings  ${resp.json()['storeTypeEncId']}  ${St_Id}
    Should Be Equal As Strings  ${resp.json()['onlineOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['walkinOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['partnerOrder']}  ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['encId']}  ${store_id}
    Should Be Equal As Strings  ${resp.json()['storeNature']}  ${storeNature[0]}
    Should Be Equal As Strings  ${resp.json()['phoneNumbers'][0]['number']}  ${PhoneNumber}
    Should Be Equal As Strings  ${resp.json()['phoneNumbers'][0]['countryCode']}  ${countryCodes[0]}
    Should Be Equal As Strings  ${resp.json()['emails'][0]}  ${email_id}