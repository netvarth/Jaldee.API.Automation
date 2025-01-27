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
Resource          /ebs/TDD/Keywords.robot      
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
${pdffile}   /ebs/TDD/sample.pdf
${jpgfile}   /ebs/TDD/uploadimage.jpg
@{if_dt_list}   ${QnrDatatypes[5]}   ${QnrDatatypes[7]}
&{id_zero}   id=${0}


*** Keywords ***

Strip and split string
   [Arguments]    ${value}  ${char}
#    ${stripped}=    Remove String    ${value}    ${SPACE}
   ${status} 	${split}=  Run Keyword And Ignore Error  Split String    ${value}  ${char}
   Return From Keyword If    '${status}' == 'FAIL'    ${value}
   ${final_list} =  Create List
   FOR  ${val}  IN  @{split}
      ${stripped}=  Strip String  ${val}
      Append To List  ${final_list}  ${stripped}
   END
   Log List   ${final_list}
   Log   ${final_list}

   RETURN  ${final_list}


Compare Lists Without Order
    [Arguments]    ${list1}  ${list2}
    ${list1_copy}   Copy List  ${list1}
    ${list2_copy}   Copy List  ${list2}
    Sort List  ${list1_copy}
    Sort List  ${list2_copy}

    IF    ${list1_copy} == ${list2_copy}
        ${val}=    Set Variable    ${bool[1]}
    ELSE
        ${val}=    Set Variable    ${bool[0]}
    END
    RETURN  ${val}


Check Questions
    [Arguments]  ${resp}  ${qnid}  ${sheet}
    ${len}=  Get Length  ${resp.json()['labels']}
    ${d}=  Create Dictionary   ${colnames[0]}=${qnid}
    ${LabelVal}   getColumnValueByAnotherVal  ${sheet}  ${colnames[10]}  ${colnames[0]}  ${qnid}
    Log  ${LabelVal}
    ${qn len}=  Get Length  ${LabelVal}
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${qn len}   ${len} 	
    
    FOR  ${i}  IN RANGE   ${qn len}
        
        ${a}=  Create Dictionary   ${colnames[0]}=${qnid}  ${colnames[10]}=${LabelVal[${i}]}
        ${labelNameVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[12]}  &{a}
        Log  ${labelNameVal}
        ${strippedlbl}=  Strip String  ${labelNameVal[0]}
        Set Test Variable  ${labelNameVal${i}}  ${strippedlbl}

        ${FieldDTVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[15]}  &{a}
        Log  ${FieldDTVal}
        Set Test Variable  ${FieldDTVal${i}}  ${FieldDTVal[0]}

        ${ScopeVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[14]}  &{a}
        Log  ${ScopeVal}
        Set Test Variable  ${ScopeVal${i}}  ${ScopeVal[0]}

        ${labelValuesVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[13]}  &{a}
        Log  ${labelValuesVal}
        ${lv}=  Run Keyword If  '${FieldDTVal${i}}' == '${QnrDatatypes[1]}'   Strip and split string    ${labelValuesVal[0].strip()}  ,
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[2]}'   Strip and split string    ${labelValuesVal[0]}  ,
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[0]}'   Strip and split string    ${labelValuesVal[0]}  ,
            ...    ELSE	 Set Variable    ${labelValuesVal[0]}
        ${type}=    Evaluate     type($lv).__name__
        Run Keyword If  '${type}' == 'list' and '${FieldDTVal${i}}' == '${QnrDatatypes[0]}'  Set Test Variable  ${labelValuesVal${i}}   ${lv[0]}
        ...    ELSE	 Set Test Variable  ${labelValuesVal${i}}   ${lv}
        # Set Test Variable  ${labelValuesVal${i}}   ${lv} 

        ${minAnswersVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[21]}  &{a}
        Log  ${minAnswersVal}
        ${minAns}=  Convert To Integer  ${minAnswersVal[0]}
        Set Test Variable  ${minAnswersVal${i}}  ${minAns}

        ${maxAnswersVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[22]}  &{a}
        Log  ${maxAnswersVal}
        ${maxAns}=  Convert To Integer  ${maxAnswersVal[0]}
        Set Test Variable  ${maxAnswersVal${i}}  ${maxAns}

        ${billableVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[18]}  &{a}
        Log  ${billableVal}
        ${stripped_val}=  Strip String  ${billableVal[0]}
        Set Test Variable  ${billableVal${i}}  ${stripped_val}
        # Set Test Variable  ${billableVal${i}}  ${billableVal[0]}

        ${minVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[19]}  &{a}
        Log  ${minVal}
        ${mnv}=  Run Keyword If  '${FieldDTVal${i}}' == '${QnrDatatypes[4]}'   Split String    ${minVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[5]}'  Split String    ${minVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[0]}'  Split String    ${minVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[3]}'  Split String    ${minVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[1]}'  Convert To Integer    ${minVal[0]}
            ...    ELSE	 Set Variable    ${minVal[0]}
        ${type}=    Evaluate     type($mnv).__name__
        Run Keyword If  '${type}' == 'list'  Set Test Variable  ${minVal${i}}   ${mnv[0]}
        ...    ELSE	 Set Test Variable  ${minVal${i}}   ${mnv}

        ${maxVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[20]}  &{a}
        Log  ${maxVal}
        ${mxv}=  Run Keyword If  '${FieldDTVal${i}}' == '${QnrDatatypes[4]}'   Split String    ${maxVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[5]}'  Split String    ${maxVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[0]}'  Split String    ${maxVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[3]}'  Split String    ${maxVal[0]}  ${SPACE}
            ...    ELSE IF  '${FieldDTVal${i}}' == '${QnrDatatypes[1]}'  Convert To Integer    ${maxVal[0]}
            ...    ELSE	 Set Variable    ${maxVal[0]}
        ${type}=    Evaluate     type($mxv).__name__
        Run Keyword If  '${type}' == 'list'  Set Test Variable  ${maxVal${i}}   ${mxv[0]}
        ...    ELSE	 Set Test Variable  ${maxVal${i}}   ${mxv}

        ${filetypeVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[16]}  &{a}
        Log  ${filetypeVal}
        ${ftv}=  Run Keyword If  '${FieldDTVal${i}}' == '${QnrDatatypes[5]}'   Strip and split string    ${filetypeVal[0]}  ,
            ...    ELSE	 Set Variable    ${filetypeVal[0]}
        Set Test Variable  ${filetypeVal${i}}   ${ftv}

        ${alloweddocVal}   getColumnValueByMultipleVals  ${sheet}  ${colnames[17]}  &{a}
        Log  ${alloweddocVal}
        ${adv}=  Run Keyword If  '${FieldDTVal${i}}' == '${QnrDatatypes[5]}'   Strip and split string    ${alloweddocVal[0]}  ,
            ...    ELSE	 Set Variable    ${alloweddocVal[0]}
        Set Test Variable  ${alloweddocVal${i}}   ${adv}
        
    END

    FOR  ${i}  IN RANGE   ${len}
        ${x} =  Get Index From List  ${LabelVal}  ${resp.json()['labels'][${i}]['question']['label']}
        Should Be Equal As Strings   ${resp.json()['labels'][${i}]['question']['label']}  ${LabelVal[${x}]}
        Should Be Equal As Strings   ${resp.json()['labels'][${i}]['question']['labelName']}  ${labelNameVal${x}}
        Should Be Equal As Strings   ${resp.json()['labels'][${i}]['question']['fieldScope']}   ${ScopeVal${x}}
        Should Be Equal As Strings   ${resp.json()['labels'][${i}]['question']['billable']}   ${billableVal${x}}

        # Run Keyword If  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' != '${QnrDatatypes[5]}'
        ${value2}=    evaluate    False if $labelValuesVal${x} is None else True
        Run Keyword If   '${resp.json()['labels'][${i}]['question']['fieldDataType']}' not in @{if_dt_list} and '${value2}' != 'False'
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['labelValues']}   ${labelValuesVal${x}}
        
        Run Keyword If  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[1]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[1]}']['minAnswers']}   ${minAnswersVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[1]}']['maxAnswers']}   ${maxAnswersVal${x}}
        
        ...    ELSE IF  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[5]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['minNoOfFile']}   ${minAnswersVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['maxNoOfFile']}   ${maxAnswersVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['minSize']}   ${minVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['maxSize']}   ${maxVal${x}}
        ...    AND  Compare Lists Without Order  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['fileTypes']}   ${filetypeVal${x}}  
        ...    AND  Compare Lists Without Order  ${resp.json()['labels'][${i}]['question']['${QnrProperty[5]}']['allowedDocuments']}   ${alloweddocVal${x}}  
        
        ...    ELSE IF  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[4]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[4]}']['minAnswers']}   ${minAnswersVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[4]}']['maxAnswers']}   ${maxAnswersVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[4]}']['start']}   ${minVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[4]}']['end']}   ${maxVal${x}}

        ...    ELSE IF  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[0]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[0]}']['minNoOfLetter']}   ${minVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[0]}']['maxNoOfLetter']}   ${maxVal${x}}

        ...    ELSE IF  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[3]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[3]}']['startDate']}   ${minVal${x}}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['question']['${QnrProperty[3]}']['endDate']}   ${maxVal${x}}

        
    END

Check Answers
    [Arguments]  ${resp}  ${data}
    ${len}=  Get Length  ${resp.json()['labels']}
    ${answer}=  Set Variable  ${data}
    ${dttypes}=  Create List  '${QnrDatatypes[0]}'  '${QnrDatatypes[1]}'  '${QnrDatatypes[2]}'  '${QnrDatatypes[3]}'

    FOR  ${i}  IN RANGE   ${len}
        
        Run Keyword And Continue On Failure  Should Be Equal As Strings   ${resp.json()['labels'][${i}]['question']['id']}  ${resp.json()['labels'][${i}]['answerLine']['id']}
        Run Keyword And Continue On Failure  Should Be Equal As Strings   ${resp.json()['labels'][${i}]['answerLine']['labelName']}   ${resp.json()['labels'][${i}]['answerLine']['labelName']}
        
        Run Keyword If  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' in @{dttypes} and '${resp.json()['labels'][${i}]['question']['fieldScope']}' == '${QnrFieldScope[0]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['answerLine']['answer']}   ${answer['answerLine'][${i}]['answer']}
        
        
        ...    ELSE IF  '${resp.json()['labels'][${i}]['question']['fieldDataType']}' == '${QnrDatatypes[5]}' and '${resp.json()['labels'][${i}]['question']['fieldScope']}' == '${QnrFieldScope[0]}'
        ...    Run Keywords
        ...    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['answerLine']['answer']['${QnrDatatypes[5]}'][0]['caption']}   ${answer['answerLine'][${i}]['answer']['${QnrDatatypes[5]}'][0]['caption']}
        ...    AND  Run Keyword And Continue On Failure  Should Be Equal As Strings  ${resp.json()['labels'][${i}]['answerLine']['answer']['${QnrDatatypes[5]}'][0]['status']}   ${QnrStatus[1]}

        ...    ELSE IF   '${resp.json()['labels'][${i}]['question']['fieldScope']}' != '${QnrFieldScope[0]}'
        ...    Run Keyword And Continue On Failure   Should Not Contain   ${resp.json()['labels'][${i}]}   answerLine
        
        
    END

*** Test Cases ***

JD-TC-GetQuestionnaireforConsumer-1
    [Documentation]  Get service questionnaire after enabling it.

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
    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

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

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
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

    ${fname}=  generate_firstname
    ${lname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${CUSERNAME7}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${CUSERNAME7}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME7}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${fname}   ${resp.json()['firstName']}
    Set Suite Variable  ${cid}  ${resp.json()['id']} 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    Check Questions   ${resp}   ${qnrid}   ${sheet1}


JD-TC-GetQuestionnaireforConsumer-2
    [Documentation]  Get donation questionnaire after enabling it.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    FOR  ${i}  IN RANGE   ${len}
      ${id}  Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[0]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}'  Set Variable  ${resp.json()[${i}]['id']} 
      ${qnrid}   Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[0]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}'  Set Variable  ${resp.json()[${i}]['questionnaireId']}
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
    FOR  ${i}  IN RANGE   ${s_len}
        ${s_id}=  Run Keyword If   '${resp.json()[${i}]['name']}' in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' == '${ServiceType[2]}'   Set Variable   ${resp.json()[${i}]['id']}
        Exit For Loop If   '${s_id}' != '${None}'
    END

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

    ${resp}=   Get Donation Questionnaire By Id   ${account_id}  ${s_id}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    Check Questions   ${resp}   ${qnrid}   ${sheet1}

JD-TC-GetQuestionnaireforConsumer-3
    [Documentation]  Get service questionnaire for consumer family member

    clear_customer   ${PUSERNAME12}
    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    @{ids}=  Create List
    FOR  ${i}  IN RANGE   ${len}
        Append To List  ${ids}   ${resp.json()[${i}]['id']} 
    END
    comment   Disabling all questionnairs
    FOR  ${id}  IN   @{ids}
        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200

        ${resp1}=  Run Keyword If   '${qns.json()['status']}' == '${status[0]}'  Provider Change Questionnaire Status  ${id}  ${status[1]}  
        Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.json()}
        Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        Should Be Equal As Strings   ${qns.json()['status']}  ${status[1]}
    END

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
    FOR  ${i}  IN RANGE   ${s_len}
        ${s_id}=  Run Keyword If   '${resp.json()[${i}]['name']}' in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' == '${ServiceType[2]}'   Set Variable   ${resp.json()[${i}]['id']}
        Exit For Loop If   '${s_id}' != '${None}'
    END

    # ${resp}=   Get Service
    # Log  ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # ${s_len}=  Get Length  ${resp.json()}
    # FOR    ${i}    IN RANGE    ${s_len}
    #     IF    '${resp.json()[${i}]['name']}' in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' == '${ServiceType[2]}'
    #         ${s_id}=    Set Variable    ${resp.json()[${i}]['id']}
    #     END
    #     Exit For Loop If    '${s_id}' != '${None}'
    # END
    Set Suite Variable    ${s_id} 
    
    ${fname}=  generate_firstname
    ${lname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${CUSERNAME7}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${CUSERNAME7}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME7}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${mem_fname}=   generate_firstname
    ${mem_lname}=   FakerLibrary.last_name
    ${dob}=      FakerLibrary.date
    ${gender}    Random Element    ${Genderlist}

    ${resp}=    Add FamilyMember For ProviderConsumer     ${mem_fname}  ${mem_lname}  ${dob}  ${gender}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${mem_id}  ${resp.json()}

    ${resp}=  Get Family Members   ${cid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer View Questionnaire   ${account_id}   ${s_id}   ${mem_id}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings   ${resp.json()['questionnaireId']}  ${qnrid}
    # Should Be Equal As Strings  ${resp.json()['id']}   ${id}
    # Check Questions   ${resp}   ${qnrid}   ${sheet1}


JD-TC-GetQuestionnaireforConsumer-UH1
    [Documentation]  Get consumer creation questionnaire after enabling it.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    @{ids}=  Create List
    FOR  ${i}  IN RANGE   ${len}
        Append To List  ${ids}   ${resp.json()[${i}]['id']} 
    END
    comment   Disabling all questionnairs
    FOR  ${id}  IN   @{ids}
        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200

        ${resp1}=  Run Keyword If   '${qns.json()['status']}' == '${status[0]}'  Provider Change Questionnaire Status  ${id}  ${status[1]}  
        Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.json()}
        Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        Should Be Equal As Strings   ${qns.json()['status']}  ${status[1]}
    END

    FOR  ${i}  IN RANGE   ${len}
      ${id}  Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[4]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[3]}'  Set Variable  ${resp.json()[${i}]['id']} 
      ${qnrid}   Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[4]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[3]}'  Set Variable  ${resp.json()[${i}]['questionnaireId']}
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

    # ${fname}=  generate_firstname
    # ${lname}=  FakerLibrary.last_name
   
    # ${resp}=  AddCustomer  ${CUSERNAME7}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    # Log   ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=    Send Otp For Login    ${CUSERNAME7}    ${account_id}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200

    # ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    # ${resp}=    Verify Otp For Login   ${CUSERNAME7}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200
    # Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings   ${resp.json()}   {'id': 0}
    Should Be Equal As Strings   ${resp.json()}   ${id_zero}


JD-TC-GetQuestionnaireforConsumer-UH2
    [Documentation]  Get service questionnaire without enabling it.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    @{ids}=  Create List
    FOR  ${i}  IN RANGE   ${len}
        Append To List  ${ids}   ${resp.json()[${i}]['id']} 
    END
    comment   Disabling all questionnairs
    FOR  ${id}  IN   @{ids}
        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        
        ${resp1}=  Run Keyword If   '${qns.json()['status']}' == '${status[0]}'  Provider Change Questionnaire Status  ${id}  ${status[1]}  
        Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.json()}
        Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        Should Be Equal As Strings   ${qns.json()['status']}  ${status[1]}
    END

    FOR  ${i}  IN RANGE   ${len}
      ${id}  Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['id']} 
      ${qnrid}   Run Keyword If   '${resp.json()[${i}]['transactionType']}' == '${QnrTransactionType[3]}' and '${resp.json()[${i}]['channel']}' == '${QnrChannel[1]}' and '${resp.json()[${i}]['captureTime']}' == '${QnrcaptureTime[0]}'  Set Variable  ${resp.json()[${i}]['questionnaireId']}
      Exit For Loop If   '${id}' != '${None}'
    END

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

    # ${fname}=  generate_firstname
    # ${lname}=  FakerLibrary.last_name
   
    # ${resp}=  AddCustomer  ${CUSERNAME7}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    # Log   ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=    Send Otp For Login    ${CUSERNAME7}    ${account_id}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200

    # ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    # ${resp}=    Verify Otp For Login   ${CUSERNAME7}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200
    # Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings   ${resp.json()}   {'id': 0}
    Should Be Equal As Strings   ${resp.json()}   ${id_zero}


JD-TC-GetQuestionnaireforConsumer-UH3
    [Documentation]  Get service questionnaire with wrong service id

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${len}=  Get Length  ${resp.json()}
    @{ids}=  Create List
    FOR  ${i}  IN RANGE   ${len}
        Append To List  ${ids}   ${resp.json()[${i}]['id']} 
    END
    comment   Disabling all questionnairs
    FOR  ${id}  IN   @{ids}
        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        
        ${resp1}=  Run Keyword If   '${qns.json()['status']}' == '${status[0]}'  Provider Change Questionnaire Status  ${id}  ${status[1]}  
        Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.json()}
        Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

        ${qns}   Get Provider Questionnaire By Id   ${id}  
        Log  ${qns.content}
        Should Be Equal As Strings  ${qns.status_code}  200
        Should Be Equal As Strings   ${qns.json()['status']}  ${status[1]}
    END

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
    FOR  ${i}  IN RANGE   ${s_len}
        ${s_id}=  Run Keyword If   '${resp.json()[${i}]['name']}' not in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' != '${ServiceType[2]}'   Set Variable   ${resp.json()[${i}]['id']}
        Exit For Loop If   '${s_id}' != '${None}'
    END

    # ${fname}=  generate_firstname
    # ${lname}=  FakerLibrary.last_name
   
    # ${resp}=  AddCustomer  ${CUSERNAME7}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    # Log   ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=    Send Otp For Login    ${CUSERNAME7}    ${account_id}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200

    # ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    # ${resp}=    Verify Otp For Login   ${CUSERNAME7}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200
    # Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings   ${resp.json()}   {'id': 0}
    Should Be Equal As Strings   ${resp.json()}   ${id_zero}


JD-TC-GetQuestionnaireforConsumer-UH4
    [Documentation]  Get service questionnaire with invalid service id

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME7}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${s_id}    FakerLibrary.Numerify  %%%%

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings   ${resp.json()}   ${id_zero}
    # Should Be Equal As Strings    ${resp.status_code}    422
    # Should Be Equal As Strings   ${resp.json()}   ${SERVICE_NOT_EXIST}


JD-TC-GetQuestionnaireforConsumer-UH5
    [Documentation]  view questionnaire without consumer login

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    FOR  ${i}  IN RANGE   ${s_len}
        ${s_id}=  Run Keyword If   '${resp.json()[${i}]['name']}' not in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' != '${ServiceType[2]}'   Set Variable   ${resp.json()[${i}]['id']}
        Exit For Loop If   '${s_id}' != '${None}'
    END

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Provider Logout
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}


JD-TC-GetQuestionnaireforConsumer-UH6
    [Documentation]  view questionnaire by provider login

    ${resp}=  Encrypted Provider Login  ${PUSERNAME12}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${s_len}=  Get Length  ${resp.json()}
    FOR  ${i}  IN RANGE   ${s_len}
        ${s_id}=  Run Keyword If   '${resp.json()[${i}]['name']}' not in @{unique_snames} and '${resp.json()[${i}]['serviceType']}' != '${ServiceType[2]}'   Set Variable   ${resp.json()[${i}]['id']}
        Exit For Loop If   '${s_id}' != '${None}'
    END

    ${resp}=  Get Questionnaire List By Provider   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Provider Logout
    # Log  ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200
    

    ${resp}=  Consumer View Questionnaire  ${account_id}  ${s_id}  ${self}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings   ${resp.json()}   {'id': 0}
    Should Be Equal As Strings   ${resp.json()}   ${id_zero}
    
