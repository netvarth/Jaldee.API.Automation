*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Run Keywords  Delete All Sessions
Force Tags        Questionnaire
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           OperatingSystem
Library           /ebs/TDD/CustomKeywords.py
Library           /ebs/TDD/excelfuncs.py
Resource          /ebs/TDD/SuperAdminKeywords.robot
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py

*** Variables ***
${xlFile}      ${EXECDIR}/TDD/sampleqnr.xlsx    # DataSheet
${xlFile2}      ${EXECDIR}/TDD/qnr.xlsx    # DataSheet 2
${self}      0
@{service_names}
@{emptylist}
${mp4file}   /ebs/TDD/MP4file.mp4
${mp4mime}   video/mp4
${mp3file}   /ebs/TDD/MP3file.mp3
${mp3mime}   audio/mpeg



*** Test Cases ***

JD-TC-ValidateConsumerQuestionnaire-1
    [Documentation]  Validate service questionnaire after enabling it.

    ${wb}=  readWorkbook  ${xlFile}
    ${sheet1}  GetCurrentSheet   ${wb}
    Set Suite Variable   ${sheet1}
    ${colnames}=  getColumnHeaders  ${sheet1}
    Log List  ${colnames}
    Log List  ${QnrChannel}
    Log List  ${QnrTransactionType}
    Set Suite Variable   ${colnames}
    ${servicenames}   getColumnValuesByName  ${sheet1}  ${colnames[6]}
    Log   ${servicenames}
    Set Suite Variable   ${servicenames}

    ${resp}=  Encrypted Provider Login  ${PUSERNAME14}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${account_id}  ${resp.json()['id']}
    Set Suite Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    @{snames}=  Create List
    FOR  ${i}  IN RANGE   ${s_len}
        Append To List  ${snames}  ${resp.json()[${i}]['name']}
    END

    Remove Values From List  ${servicenames}   ${NONE}
    Log  ${servicenames}
    ${unique_snames}=    Remove Duplicates    ${servicenames}
    Log  ${unique_snames}
    Set Suite Variable   ${unique_snames}
    ${snames_len}=  Get Length  ${unique_snames}
    FOR  ${i}  IN RANGE   ${snames_len}
        IF  '${unique_snames[${i}]}' not in @{snames}
            &{dict}=  Create Dictionary   ${colnames[6]}=${unique_snames[${i}]}
            ${ttype}=  getColumnValueByMultipleVals  ${sheet1}  ${colnames[1]}  &{dict}  
            Log  ${ttype}
            ${u_ttype}=    Remove Duplicates    ${ttype}
            Log  ${u_ttype}
            IF  '${QnrTransactionType[3]}' in @{u_ttype}
                ${s_id}=    Create Sample Service    ${unique_snames[${i}]}
            ELSE IF   '${QnrTransactionType[0]}' in @{u_ttype}
                ${d_id}=    Create Sample Donation    ${unique_snames[${i}]}
            END
        END
    END

    ${resp}=  Provider Logout
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${cookie}  ${resp}=  Imageupload.SALogin    ${SUSERNAME}  ${SPASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Imageupload.UploadQuestionnaire   ${cookie}   ${account_id}    ${xlFile}   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME14}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    FOR  ${i}  IN RANGE   ${len}
      ${id}  Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['id']} 
      ${qnrid}   Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['questionnaireId']}
      Exit For Loop If   '${id}' != '${None}'
    END
    Set Suite Variable   ${id}
    Set Suite Variable   ${qnrid}

    ${qns}   Get Provider Questionnaire By Id   ${id}  
    Log  ${qns.content}
    Should Be Equal As Strings  ${qns.status_code}  200

    IF  '${qns.json()['status']}' == '${status[1]}' 
        ${resp1}=   Provider Change Questionnaire Status  ${id}  ${status[0]}  
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${qns}   Get Provider Questionnaire By Id   ${id}  
    Log  ${qns.content}
    Should Be Equal As Strings  ${qns.status_code}  200
    Should Be Equal As Strings   ${qns.json()['status']}  ${status[0]}
    Set Suite Variable  ${Questionnaireid}  ${qns.json()['questionnaireId']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    FOR    ${i}    IN RANGE    ${s_len}
        IF    '${resp.json()[${i}]["name"]}' in @{unique_snames} and '${resp.json()[${i}]["serviceType"]}' != '${ServiceType[2]}'
            ${s_id}=    Set Variable    ${resp.json()[${i}]["id"]}
        END
        Exit For Loop If    '${s_id}' != '${None}'
    END
    Set Suite Variable   ${s_id}

    ${fname}=  generate_firstname
    ${lname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${CUSERNAME8}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-ValidateConsumerQuestionnaire-2

    [Documentation]  Validate service questionnaire with wrong caption.

    # ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}

    ${len}=  Get Length  ${resp.json()['labels']}
    FOR  ${i}  IN RANGE   ${len}
        ${filetypes}=  Run Keyword If  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[5]}'
        ...   Set Variable   ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['fileTypes']}
        ...  ELSE  Continue For Loop

        Run Keyword If  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[5]}' and 'jpeg' in @{filetypes}
        ...  Run Keywords
        ...  Set Test Variable  ${filedocs}  ${resp.json()['labels'][${i}]['question']['filePropertie']['allowedDocuments']}
        ...  AND  Set Suite Variable  ${fileLabelName}  ${resp.json()['labels'][${i}]['question']['labelName']}

    END
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    ${caption}=  FakerLibrary.word
    Set to Dictionary   ${fudata['fileupload'][0]['files'][0]}   caption=${caption}

    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()[0]['questionField']}   ${fileLabelName}
    # Should Be Equal As Strings  ${resp.json()[0]['error']}   ${INCORRECT_DOUMENT}


JD-TC-ValidateConsumerQuestionnaire-3

    [Documentation]  Validate service questionnaire without caption.

    # ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    Set to Dictionary      ${fudata['fileupload'][0]['files'][0]}    caption=${EMPTY}

    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()[0]['questionField']}   ${fileLabelName}
    # Should Be Equal As Strings  ${resp.json()[0]['error']}   ${INCORRECT_DOUMENT}


JD-TC-ValidateConsumerQuestionnaire-UH1
    [Documentation]  Validate service questionnaire without index.

    # ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    Set to Dictionary      ${fudata['fileupload'][0]['files'][0]}    index=${EMPTY}
    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}    []


JD-TC-ValidateConsumerQuestionnaire-UH2
    [Documentation]  Validate service questionnaire with incorrect action.

    # ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[1]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    
    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}    []


# JD-TC-ValidateConsumerQuestionnaire-UH3
#     [Documentation]  Validate service questionnaire with invalid action.

#     ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200 

#     ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
#     Log  ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
#     Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
#     ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
#     Log  ${fudata}

#     ${action}=  FakerLibrary.word
#     Set to Dictionary      ${fudata['fileupload'][0]['files'][0]}    action=${action}

#     Log  ${fudata}

#     ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
#     Log  ${data}
#     ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
#     Log  ${resp.content}
#     Should Be Equal As Strings  ${resp.status_code}  422


# JD-TC-ValidateConsumerQuestionnaire-UH4
#     [Documentation]  Validate service questionnaire without action.

#     ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200 

#     ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
#     Log  ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
#     Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
#     ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
#     Log  ${fudata}

#     Set to Dictionary      ${fudata['fileupload'][0]['files'][0]}    action=${EMPTY}

#     Log  ${fudata}

#     ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
#     Log  ${data}
#     ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
#     Log  ${resp.content}
#     Should Be Equal As Strings  ${resp.status_code}  422


JD-TC-ValidateConsumerQuestionnaire-UH5
    [Documentation]  Validate service questionnaire without consumer login.

    # ${resp}=  Consumer Login  ${CUSERNAME8}  ${PASSWORD} 
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    
    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    Set Suite Variable  ${data}

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}    []

JD-TC-ValidateConsumerQuestionnaire-UH6

    [Documentation]  Validate service questionnaire by provider login.
    
    ${resp}=  Encrypted Provider Login  ${PUSERNAME14}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}    []


JD-TC-ValidateConsumerQuestionnaire-4
    [Documentation]  Validate service questionnaire for a different questionnaire file.

    ${wb}=  readWorkbook  ${xlFile2}
    ${sheet1}  GetCurrentSheet   ${wb}
    Set Suite Variable   ${sheet1}
    ${colnames}=  getColumnHeaders  ${sheet1}
    Log List  ${colnames}
    Log List  ${QnrChannel}
    Log List  ${QnrTransactionType}
    Set Suite Variable   ${colnames}
    ${servicenames}   getColumnValuesByName  ${sheet1}  ${colnames[6]}
    Log   ${servicenames}
    Set Suite Variable   ${servicenames}

    ${resp}=  Encrypted Provider Login  ${PUSERNAME15}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${account_id}  ${resp.json()['id']}
    Set Suite Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    @{snames}=  Create List
    FOR  ${i}  IN RANGE   ${s_len}
        Append To List  ${snames}  ${resp.json()[${i}]['name']}
    END

    Remove Values From List  ${servicenames}   ${NONE}
    Log  ${servicenames}
    ${unique_snames}=    Remove Duplicates    ${servicenames}
    Log  ${unique_snames}
    Set Suite Variable   ${unique_snames}
    ${snames_len}=  Get Length  ${unique_snames}
    FOR  ${i}  IN RANGE   ${snames_len}
        IF  '${unique_snames[${i}]}' not in @{snames}
            &{dict}=  Create Dictionary   ${colnames[6]}=${unique_snames[${i}]}
            ${ttype}=  getColumnValueByMultipleVals  ${sheet1}  ${colnames[1]}  &{dict}  
            Log  ${ttype}
            ${u_ttype}=    Remove Duplicates    ${ttype}
            Log  ${u_ttype}
            IF  '${QnrTransactionType[3]}' in @{u_ttype}
                ${s_id}=    Create Sample Service    ${unique_snames[${i}]}
            ELSE IF   '${QnrTransactionType[0]}' in @{u_ttype}
                ${d_id}=    Create Sample Donation    ${unique_snames[${i}]}
            END
        END
    END

    ${resp}=  Provider Logout
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${cookie}  ${resp}=  Imageupload.SALogin    ${SUSERNAME}  ${SPASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Imageupload.UploadQuestionnaire   ${cookie}   ${account_id}  ${xlFile2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME15}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    FOR  ${i}  IN RANGE   ${len}
      ${id}  Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['id']} 
      ${qnrid}   Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['questionnaireId']}
      Exit For Loop If   '${id}' != '${None}'
    END

    ${qns}   Get Provider Questionnaire By Id   ${id}  
    Log  ${qns.content}
    Should Be Equal As Strings  ${qns.status_code}  200

    IF  '${qns.json()['status']}' == '${status[1]}' 
        ${resp1}=   Provider Change Questionnaire Status  ${id}  ${status[0]}  
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${qns}   Get Provider Questionnaire By Id   ${id}  
    Log  ${qns.content}
    Should Be Equal As Strings  ${qns.status_code}  200
    Should Be Equal As Strings   ${qns.json()['status']}  ${status[0]}
    Set Suite Variable  ${Questionnaireid}  ${qns.json()['questionnaireId']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    FOR    ${i}    IN RANGE    ${s_len}
        IF    '${resp.json()[${i}]["name"]}' in @{unique_snames} and '${resp.json()[${i}]["serviceType"]}' != '${ServiceType[2]}'
            ${s_id}=    Set Variable    ${resp.json()[${i}]["id"]}
        END
        Exit For Loop If    '${s_id}' != '${None}'
    END
    Set Suite Variable   ${s_id}

    ${fname}=  generate_firstname
    ${lname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${CUSERNAME8}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${CUSERNAME8}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME8}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME8}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}

    ${fudata}=  db.fileUploadDT   ${resp.json()}  ${FileAction[0]}  ${mp4file}  ${mp3file}
    Log  ${fudata}

    ${data}=  db.QuestionnaireAnswers   ${resp.json()}   ${self}   &{fudata}
    Log  ${data}
    ${resp}=  Consumer Validate Questionnaire  ${account_id}  ${data}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200




