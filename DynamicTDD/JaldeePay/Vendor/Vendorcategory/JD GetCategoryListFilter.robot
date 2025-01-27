*** Settings ***

Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Finance Manager
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           /ebs/TDD/CustomKeywords.py
Library           /ebs/TDD/db.py
Library           /ebs/TDD/excelfuncs.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py 


*** Test Cases ***


JD-TC-Get Category List Filter-1

    [Documentation]  Get VendorCategory With Filter with name.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}

    Set Suite Variable  ${pid}  ${decrypted_data['id']}
    Set Suite Variable    ${userName}    ${decrypted_data['userName']}
    Set Suite Variable    ${pdrfname}    ${decrypted_data['firstName']}
    Set Suite Variable    ${pdrlname}    ${decrypted_data['lastName']}

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}


    ${resp}=  Populate Url For Vendor   ${account_id1}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200


    ${loc_id1}=   Create Sample Location
    ${resp}=   Get Location ById  ${loc_id1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

    ${CUR_DAY}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable    ${CUR_DAY} 

    ${DAY2}=  db.add_timezone_date  ${tz}  10    
    Set Suite Variable    ${DAY2} 

    ${name}=   FakerLibrary.word
    Set Suite Variable    ${name} 
    ${resp}=  CreateVendorCategory  ${name}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${encId}   ${resp.json()}


    ${resp}=   Get VendorCategory With Filter   name-eq=${name}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()[0]['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()[0]['status']}        ${toggle[0]}

JD-TC-Get Category List Filter-2

    [Documentation]  Get VendorCategory With Filter with createdDate

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorCategory With Filter   createdDate-ge=${CUR_DAY}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()[0]['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()[0]['status']}        ${toggle[0]}

JD-TC-Get Category List Filter-3

    [Documentation]  Get VendorCategory With Filter with status

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorCategory With Filter   status-eq=${toggle[0]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()[0]['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()[0]['status']}        ${toggle[0]}

JD-TC-Get Category List Filter-4

    [Documentation]  Get VendorCategory With Filter with encId

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorCategory With Filter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()[0]['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()[0]['status']}        ${toggle[0]}

JD-TC-Get Category List Filter-5

    [Documentation]  Get VendorCategory With Filter with all fileds

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorCategory With Filter   encId-eq=${encId}   status-eq=${toggle[0]}  createdDate-ge=${CUR_DAY}  name-eq=${name}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()[0]['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()[0]['status']}        ${toggle[0]}


JD-TC-Get Category List Filter-UH1

    [Documentation]   Get VendorCategory With Filter without login

    ${resp}=   Get VendorCategory With Filter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}

JD-TC-Get Category List Filter-UH2

    [Documentation]   Get VendorCategory With Filter Using Consumer Login

    ${resp}=  Encrypted Provider Login  ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${PH_Number}    Random Number 	       digits=5 
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable    ${consumerPhone}  555${PH_Number}
    Append To File  ${EXECDIR}/data/TDD_Logs/proconnum.txt  ${SUITE NAME} - ${TEST NAME} - ${consumerPhone}${\n}
    ${fname}=   generate_firstname
    ${lname}=    FakerLibrary.last_name
    Set Test Variable      ${fname}
    Set Test Variable      ${lname}  
    ${dob}=    FakerLibrary.Date
    ${permanentAddress1}=  FakerLibrary.address
    ${gender}=  Random Element    ${Genderlist}
    Set Test Variable  ${consumerEmail}  ${C_Email}${consumerPhone}${fname}.${test_mail}

    ${resp}=  AddCustomer  ${consumerPhone}  firstName=${fname}   lastName=${lname}  address=${permanentAddress1}   gender=${gender}  dob=${dob}  email=${consumerEmail}   
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${ageyrs}  ${agemonths}=  db.calculate_age_years_months     ${dob}

    ${resp}=  GetCustomer  phoneNo-eq=${consumerPhone}
    Log   ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}  200
    Set Test Variable  ${consumerId}  ${resp.json()[0]['id']}
    ${fullName}   Set Variable    ${fname} ${lname}
    Set Test Variable  ${fullName}

    ${resp}=  Provider Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${consumerPhone}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id1}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get VendorCategory With Filter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  401
    Should Be Equal As Strings   ${resp.json()}   ${LOGIN_NO_ACCESS_FOR_URL}


JD-TC-Get Category List Filter-UH3

    [Documentation]  Get VendorCategory With Filter where encId as wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
     ${fake}=    Random Int  min=1000000   max=9999999   
    ${resp}=   Get VendorCategory With Filter   encId-eq=${fake}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   []

JD-TC-Get Category List Filter-UH4

    [Documentation]  Get VendorCategory With Filter where created date is wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
     ${fake}=    Random Int  min=1000000   max=9999999   
    ${resp}=   Get VendorCategory With Filter   createdDate-ge=${DAY2}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   []

JD-TC-Get Category List Filter-UH5

    [Documentation]  Get VendorCategory With Filter where name  is wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
    ${name}=   FakerLibrary.word
    ${resp}=   Get VendorCategory With Filter   name-eq=${name}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   []

JD-TC-Get Category List Filter-UH6

    [Documentation]  Get VendorCategory With Filter with status

    ${resp}=  Encrypted Provider Login    ${PUSERNAME95}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorCategory With Filter   status-eq=${toggle[1]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   []



