*** Settings ***

Suite Teardown    Run Keywords  Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Consent FOrm
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           /ebs/TDD/Imageupload.py
Resource          /ebs/TDD/SuperAdminKeywords.robot
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Library           /ebs/TDD/excelfuncs.py


*** Variables ***

${xlFile}    ${EXECDIR}/TDD/ConsentForm.xlsx

${xlFile}    ${EXECDIR}/TDD/ConsentForm.xlsx
${self}    0
${jpgfile}      /ebs/TDD/uploadimage.jpg
${order}        0
${fileSize}     0.00458

*** Test Cases ***

JD-TC-GetConsentFormByUid-1

    [Documentation]  Get Consent Form By Uid

    ${resp}=  Encrypted Provider Login  ${PUSERNAME291}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Provider Logout
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${cookie}  ${resp}=  Imageupload.SALogin    ${SUSERNAME}  ${SPASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Imageupload.UploadQuestionnaire   ${cookie}   ${account_id}   ${xlFile}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Questionnaire List   ${account_id}  
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${qnr_id}  ${resp.json()[0]['id']}

    ${resp1}=  Run Keyword If   '${resp.json()[0]['status']}' == '${status[1]}'  Superadmin Change Questionnaire Status  ${qnr_id}  ${status[0]}  ${account_id}
    Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.json()}
    Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

    ${qnr_name}=    FakerLibrary.name
    ${qnr_des}=     FakerLibrary.sentence
    ${qnr_ids}=     Create List  ${qnr_id}
    Set Suite Variable      ${qnr_ids}

    ${resp}=  SuperAdmin Logout
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200  

    ${resp}=  Encrypted Provider Login  ${PUSERNAME291}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    IF  '${resp.json()['enableConsentForm']}'=='${bool[0]}'

        ${resp}=    Enable Disable Provider Consent Form   ${toggle[0]}
        Log  ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200

    END

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableConsentForm']}     ${bool[1]}

    ${PH_Number}    Random Number 	       digits=5 
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable    ${consumerPhone}  555${PH_Number}
    Append To File  ${EXECDIR}/TDD/TDD_Logs/proconnum.txt  ${SUITE NAME} - ${TEST NAME} - ${consumerPhone}${\n}
    ${consumerFirstName}=   FakerLibrary.first_name
    Set Suite Variable  ${consumerFirstName}
    ${consumerLastName}=    FakerLibrary.last_name  
    ${dob}=    FakerLibrary.Date
    ${permanentAddress1}=  FakerLibrary.address
    ${gender}=  Random Element    ${Genderlist}
    Set Test Variable  ${consumerEmail}  ${C_Email}${consumerPhone}${consumerFirstName}.${test_mail}

    ${resp}=  AddCustomer  ${consumerPhone}  firstName=${consumerFirstName}   lastName=${consumerLastName}  address=${permanentAddress1}   gender=${gender}  dob=${dob}  email=${consumerEmail}   
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  GetCustomer  phoneNo-eq=${consumerPhone}
    Log   ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}  200
    Set Suite Variable  ${consumerId}  ${resp.json()[0]['id']}
    ${fullName}   Set Variable    ${consumerFirstName} ${consumerLastName}
    Set Suite Variable  ${fullName}

    ${qnr_name}=    FakerLibrary.name
    Set Suite Variable  ${qnr_name}
    ${qnr_des}=     FakerLibrary.sentence
    Set Suite Variable  ${qnr_des}
    ${qnr_ids}=     Create List  ${qnr_id}
    Set Suite Variable   ${qnr_ids}

    ${resp}=    Create Provider Consent Form Settings  ${qnr_name}  ${qnr_des}  ${qnr_ids}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Provider Consent Form Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable          ${cfid}     ${resp.json()[0]['id']}
    Should Be Equal As Strings  ${resp.json()[0]['name']}           ${qnr_name}
    Should Be Equal As Strings  ${resp.json()[0]['description']}    ${qnr_des}
    Should Be Equal As Strings  ${resp.json()[0]['qnrIds']}         ${qnr_ids}

    ${resp}=    Share Consent Form  ${boolean[1]}  ${boolean[1]}  ${boolean[1]}  ${boolean[1]}  ${cfid}  ${boolean[1]}  ${boolean[1]}  ${consumerId}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${cf_uid}   ${resp.json()}

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}
    Set Suite Variable    ${PCid}   ${resp.json()['id']}

    ${resp}=    Consumer Get Consent Form By Uid  ${cf_uid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Get Verify Status of consent form by uid  ${cf_uid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings  ${resp.json()}       ${bool[0]}

    ${resp}=    Consumer Comsent Form Sent Otp   ${cf_uid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Comsent Form Verify Otp  ${OtpPurpose['CONSENT_FORM']}  ${cf_uid}   ${consumerPhone}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  db.getType   ${jpgfile}
    Log  ${resp}
    ${fileType1}=  Get From Dictionary       ${resp}    ${jpgfile}
    Set Suite variable    ${fileType1}
    ${caption1}=  Fakerlibrary.Sentence
    Set Suite variable    ${caption1}
    ${fileName}=    FakerLibrary.firstname
    Set Suite variable    ${fileName}

    ${resp}=    upload file to temporary location consumer    ${file_action[0]}    ${consumerId}    ${ownerType[0]}    ${fullName}    ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}    ${EMPTY}    ${order}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    200 
    Set Suite Variable    ${driveId}    ${resp.json()[0]['driveId']}

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    200

    ${resp}=    Consumer Get Verify Status of consent form by uid  ${cf_uid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings  ${resp.json()}       ${bool[1]}









JD-TC-ConsentFormVerifySign-UH1

    [Documentation]  Consumer Consent Form Verify Sign - where uid is invalid

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${fake}=    Random Int  min=9999    max=99999

    ${resp}=    Consumer Consent Form Verify Sign  ${fake}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422

JD-TC-ConsentFormVerifySign-UH3

    [Documentation]  Consumer Consent Form Verify Sign - consumer id is empty

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${empty}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422

JD-TC-ConsentFormVerifySign-UH4

    [Documentation]  Consumer Consent Form Verify Sign - consumer id is invalid

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${fake}=    Random Int  min=9999    max=99999

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${fake}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422

JD-TC-ConsentFormVerifySign-UH5

    [Documentation]  Consumer Consent Form Verify Sign - file name is empty

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${empty}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422
    Should Be Equal As Strings     ${resp.json()}         ${FILE_NAME_NOT_FOUND}

JD-TC-ConsentFormVerifySign-UH6

    [Documentation]  Consumer Consent Form Verify Sign - file size is empty

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${empty}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422
    Should Be Equal As Strings     ${resp.json()}         ${FILE_SIZE_ERROR}

JD-TC-ConsentFormVerifySign-UH7

    [Documentation]  Consumer Consent Form Verify Sign - file action is remove

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[1]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    200

JD-TC-ConsentFormVerifySign-UH8

    [Documentation]  Consumer Consent Form Verify Sign - driveid is empty

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${empty}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422
    Should Be Equal As Strings     ${resp.json()}         ${S3_UPLOAD_FAILED}

JD-TC-ConsentFormVerifySign-UH9

    [Documentation]  Consumer Consent Form Verify Sign - drive id is invalid

    ${resp}=    Send Otp For Login    ${consumerPhone}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${consumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${consumerPhone}    ${account_id}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${fake}=    Random Int  min=9999    max=99999

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${fake}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    422
    Should Be Equal As Strings     ${resp.json()}         ${INV_DRIVE_ID}

JD-TC-ConsentFormVerifySign-UH10

    [Documentation]  Consumer Consent Form Verify Sign - without login

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    419
    Should Be Equal As Strings     ${resp.json()}         ${SESSION_EXPIRED}

JD-TC-ConsentFormVerifySign-UH11

    [Documentation]  Consumer Consent Form Verify Sign - with provider login

    ${resp}=  Encrypted Provider Login  ${PUSERNAME291}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Consumer Consent Form Verify Sign  ${cf_uid}  ${consumerId}  ${jpgfile}    ${fileSize}    ${caption1}    ${fileType1}  ${file_action[0]}  ${order}  ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings     ${resp.status_code}    401
    Should Be Equal As Strings     ${resp.json()}         ${NO_PERMISSION}