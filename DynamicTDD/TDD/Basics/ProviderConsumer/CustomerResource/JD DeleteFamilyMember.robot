*** Settings ***

Suite Teardown    Delete All Sessions
Test Teardown    Delete All Sessions
Force Tags        ConsumerSignup
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/consumermail.py


*** Variables ***

${cc}                               +91

*** Test Cases ***

JD-TC-DeleteFamilyMembers-1
    
    [Documentation]  Delete Provider Consumer Family Member
    
    ${resp}=  Encrypted Provider Login  ${PUSERNAME22}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=    get_acc_id       ${PUSERNAME22}
    Set Suite Variable    ${accountId}

    ${gender}                     Random Element    ${Genderlist}                   
    ${dob}                        FakerLibrary.Date
    ${fname}                      FakerLibrary. name
    ${lname}                      FakerLibrary.last_name
    ${email}                      FakerLibrary.email
    ${city}                       FakerLibrary.city
    ${state}                      FakerLibrary.state
    ${address}                    FakerLibrary.address
    ${primnum}                    FakerLibrary.Numerify   text=%%%%%%%%%%
    ${altno}                      FakerLibrary.Numerify   text=%%%%%%%%%%
    ${numt}                       FakerLibrary.Numerify   text=%%%%%%%%%%
    ${numw}                       FakerLibrary.Numerify   text=%%%%%%%%%%

    Set Suite Variable      ${gender}
    Set Suite Variable      ${dob}
    Set Suite Variable      ${fname}
    Set Suite Variable      ${lname}
    Set Suite Variable      ${email}
    Set Suite Variable      ${city}
    Set Suite Variable      ${state}
    Set Suite Variable      ${address}
    Set Suite Variable      ${primnum}
    Set Suite Variable      ${altno}
    Set Suite Variable      ${numt}
    Set Suite Variable      ${numw}

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  '${resp.json()['walkinConsumerBecomesJdCons']}'=='${bool[0]}' and '${resp.json()['onlinePresence']}'=='${bool[0]}'
        ${resp1}=   Set jaldeeIntegration Settings    ${boolean[1]}  ${boolean[1]}  ${boolean[0]}
        Should Be Equal As Strings  ${resp1.status_code}  200
    ELSE IF    '${resp.json()['walkinConsumerBecomesJdCons']}'=='${bool[0]}' and '${resp.json()['onlinePresence']}'=='${bool[1]}'
        ${resp1}=   Set jaldeeIntegration Settings    ${EMPTY}  ${boolean[1]}  ${boolean[0]}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${resp}=   Get jaldeeIntegration Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['walkinConsumerBecomesJdCons']}   ${bool[1]}



    ${resp1}=  AddCustomer  ${CUSERNAME13}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable  ${pcid18}   ${resp1.json()}
   
    ${resp}=  Provider Logout
    Should Be Equal As Strings    ${resp.status_code}    200
  
    ${resp}=    Send Otp For Login    ${CUSERNAME13}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${CUSERNAME13}   ${OtpPurpose['Authentication']}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${CUSERNAME13}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    Add FamilyMember For ProviderConsumer    ${fname}  ${lname}  ${dob}  ${gender}  ${primnum}  email=${email}  city=${city}  state=${state}   address=${address}  alternativePhoneNo=${altno}  countryCode=${cc}  telegramCC=${cc}  telegramNum=${numt}  whatsAppCC=${cc}  whatsAppNum=${numw}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get FamilyMember
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable     ${Famid}    ${resp.json()[0]['id']}

    ${resp}=    Delete ProCons FamilyMember    ${Famid}
    Log  ${resp.json()}
    Should Be Equal AS Strings     ${resp.status_code}   200

    ${resp}=    Get FamilyMember
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-DeleteFamilyMembers-UH1
    
    [Documentation]  Delete Provider with invalid family member id

    ${resp}=    ProviderConsumer Login with token    ${CUSERNAME13}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    Add FamilyMember For ProviderConsumer    ${fname}  ${lname}  ${dob}  ${gender}  ${primnum}  email=${email}  city=${city}  state=${state}   address=${address}  alternativePhoneNo=${altno}  countryCode=${cc}  telegramCC=${cc}  telegramNum=${numt}  whatsAppCC=${cc}  whatsAppNum=${numw}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get FamilyMember
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable     ${Famid}    ${resp.json()[0]['id']}

    # ${inv_FamId}=  Generate Random String  3  [NUMBERS]
    ${inv_FamId}=  Random Int  min=1000  max=2000

    ${resp}=    Delete ProCons FamilyMember    ${inv_FamId}
    Log  ${resp.json()}
    Should Be Equal AS Strings     ${resp.status_code}   422
    Should Be Equal AS Strings    ${resp.json()}    ${FAMILY_MEMEBR_NOT_FOUND}

JD-TC-DeleteFamilyMembers-UH2
    
    [Documentation]  Delete Provider without login

    ${resp}=    Delete ProCons FamilyMember    ${Famid}
    Log  ${resp.json()}
    Should Be Equal AS Strings     ${resp.status_code}   419
    Should Be Equal AS Strings    ${resp.json()}    ${SESSION_EXPIRED}