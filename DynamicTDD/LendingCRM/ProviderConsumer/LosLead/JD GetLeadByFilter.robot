*** Settings ***
Suite Teardown                  Delete All Sessions
Test Teardown                   Delete All Sessions
Force Tags                      LOS Lead
Library                         Collections
Library                         String
Library                         json
Library                         FakerLibrary
Library                         /ebs/TDD/db.py
Library                         /ebs/TDD/excelfuncs.py
Resource                        /ebs/TDD/ProviderKeywords.robot
Resource                        /ebs/TDD/ConsumerKeywords.robot
Resource                        /ebs/TDD/ProviderConsumerKeywords.robot
Resource                        /ebs/TDD/ProviderPartnerKeywords.robot
Variables                       /ebs/TDD/varfiles/providers.py
Variables                       /ebs/TDD/varfiles/consumerlist.py 
Variables                       /ebs/TDD/varfiles/musers.py
Variables                       /ebs/TDD/varfiles/hl_musers.py

*** Variables ***

${losProduct}                    CDL
${aadhaar}                       555555555555
${pan}                           5555555555
${bankAccountNo}                 55555555555
${bankIfsc}                      55555555555

*** Test Cases ***

JD-TC-GetLeadByFilter-1

    [Documentation]             Get Lead By Filter

    ${resp}=  Encrypted Provider Login  ${PUSERNAME86}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=    get_acc_id       ${PUSERNAME86}

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${account_id}  ${resp.json()['id']}
    Set Suite Variable  ${tz}  ${resp.json()['baseLocation']['bSchedule']['timespec'][0]['timezone']}

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

    ${PH_Number}    Random Number 	       digits=5 
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable    ${PconsumerPhone}  555${PH_Number}

    ${resp1}=  AddCustomer  ${PconsumerPhone}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable  ${pcid18}   ${resp1.json()}
   
    ${resp}=  Provider Logout
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    FOR    ${i}    IN RANGE  0  3
        ${pin}=  get_pincode
        ${kwstatus}  ${resp} =   Run Keyword And Ignore Error  Get LocationsByPincode  ${pin}
        IF    '${kwstatus}' == 'FAIL'
                Continue For Loop
        ELSE IF    '${kwstatus}' == 'PASS'
                Exit For Loop
        END
    END
    Log  ${resp.content}
    Should Be Equal As Strings      ${resp.status_code}    200
    Set Suite Variable  ${city}      ${resp.json()[0]['PostOffice'][0]['District']}   
    Set Suite Variable  ${permanentState}     ${resp.json()[0]['PostOffice'][0]['State']}    
    Set Suite Variable  ${permanentDistrict}  ${resp.json()[0]['PostOffice'][0]['District']}   
    Set Suite Variable  ${permanentPin}       ${resp.json()[0]['PostOffice'][0]['Pincode']}

    ${requestedAmount}=     Random Int  min=30000  max=600000
    Set Suite Variable      ${requestedAmount}
    ${description}=         FakerLibrary.bs
    Set Suite Variable      ${description}
    ${consumerFirstName}=   FakerLibrary.first_name
    Set Suite Variable      ${consumerFirstName}
    ${consumerLastName}=    FakerLibrary.last_name  
    Set Suite Variable      ${consumerLastName}
    ${dob}=    FakerLibrary.Date
    Set Suite Variable      ${dob}
    ${address}=  FakerLibrary.address
    Set Suite Variable      ${address}
    ${gender}=  Random Element    ${Genderlist}
    Set Suite Variable      ${gender}
    Set Suite Variable  ${consumerEmail}  ${C_Email}${PconsumerPhone}.${test_mail}   
    ${permanentAddress1}=   FakerLibrary.address
    ${permanentAddress2}=   FakerLibrary.address  
    ${nomineeName}=     FakerLibrary.first_name
    ${consumerKyc}=   Create Dictionary  consumerFirstName=${consumerFirstName}  consumerLastName=${consumerLastName}  dob=${dob}  gender=${gender}  consumerPhoneCode=${countryCodes[1]}   consumerPhone=${PconsumerPhone}  consumerEmail=${consumerEmail}  aadhaar=${aadhaar}  pan=${pan}  bankAccountNo=${bankAccountNo}  bankIfsc=${bankIfsc}  permanentAddress1=${permanentAddress1}  permanentAddress2=${permanentAddress2}  permanentDistrict=${permanentDistrict}  permanentState=${permanentState}  permanentPin=${permanentPin}  nomineeType=${nomineeType[2]}  nomineeName=${nomineeName}

    ${resp}=    PC Create Lead LOS  ${leadchannel[0]}  ${description}  ${losProduct}  ${requestedAmount}  consumerKyc=${consumerKyc}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${lead_uid}      ${resp.json()['uid']}

    ${resp}=    PC Get Lead By Uid LOS   ${lead_uid}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${kycid}             ${resp.json()['consumerKyc']['id']}
    Set Suite Variable      ${referenceNo}       ${resp.json()['referenceNo']}
    Set Suite Variable      ${createdDate}       ${resp.json()['createdDate']}
    Set Suite Variable      ${consumerId}        ${resp.json()['consumerKyc']['consumerId']} 
    Set Suite Variable      ${internalProgress}  ${resp.json()['internalProgress']}
    Set Suite Variable      ${internalStatus}    ${resp.json()['internalStatus']}

    ${PH_Number}    Random Number 	       digits=5 
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable    ${consumerPhone2}  555${PH_Number}
    ${requestedAmount2}=     Random Int  min=30000  max=600000
    Set Suite Variable  ${requestedAmount2}
    ${description2}=         FakerLibrary.bs
    Set Suite Variable  ${description2}
    ${consumerFirstName2}=   FakerLibrary.first_name
    Set Suite Variable  ${consumerFirstName2}
    ${consumerLastName2}=    FakerLibrary.last_name  
    Set Suite Variable  ${consumerLastName2}
    ${dob2}=    FakerLibrary.Date
    Set Suite Variable  ${dob2}
    ${address2}=  FakerLibrary.address
    Set Suite Variable  ${address2}
    ${gender2}=  Random Element    ${Genderlist}
    Set Suite Variable  ${gender2}
    Set Suite Variable  ${consumerEmail2}  ${C_Email}${consumerPhone2}.${test_mail}   
    ${permanentAddress11}=   FakerLibrary.address
    ${permanentAddress22}=   FakerLibrary.address  
    ${nomineeName2}=     FakerLibrary.first_name
    ${consumerKyc}=   Create Dictionary  consumerFirstName=${consumerFirstName2}  consumerLastName=${consumerLastName2}  dob=${dob2}  gender=${gender2}  consumerPhoneCode=${countryCodes[1]}   consumerPhone=${consumerPhone2}  consumerEmail=${consumerEmail2}  aadhaar=${aadhaar}  pan=${pan}  bankAccountNo=${bankAccountNo}  bankIfsc=${bankIfsc}  permanentAddress1=${permanentAddress11}  permanentAddress2=${permanentAddress22}  permanentDistrict=${permanentDistrict}  permanentState=${permanentState}  permanentPin=${permanentPin}  nomineeType=${nomineeType[2]}  nomineeName=${nomineeName2}

    ${resp}=    PC Create Lead LOS  ${leadchannel[0]}  ${description2}  ${losProduct}  ${requestedAmount2}  consumerKyc=${consumerKyc}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${lead_uid2}      ${resp.json()['uid']}

    ${resp}=    PC Get Lead By Uid LOS   ${lead_uid2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${kycid2}             ${resp.json()['consumerKyc']['id']}
    Set Suite Variable      ${referenceNo2}       ${resp.json()['referenceNo']}
    Set Suite Variable      ${createdDate2}       ${resp.json()['createdDate']}
    Set Suite Variable      ${consumerId2}        ${resp.json()['consumerKyc']['consumerId']} 
    Set Suite Variable      ${internalProgress2}  ${resp.json()['internalProgress']}
    Set Suite Variable      ${internalStatus2}    ${resp.json()['internalStatus']}

    ${resp}=    PC Get Lead By Filter LOS
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-2

    [Documentation]             Get Lead By Filter with uid

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-3

    [Documentation]             Get Lead By Filter with referenceNo

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-4

    [Documentation]             Get Lead By Filter with losProduct

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-5

    [Documentation]             Get Lead By Filter with consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-6

    [Documentation]             Get Lead By Filter with consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-7

    [Documentation]             Get Lead By Filter with consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    
    
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-8

    [Documentation]             Get Lead By Filter with createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}      200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-9

    [Documentation]             Get Lead By Filter with isConverted false

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   isConverted-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-10

    [Documentation]             Get Lead By Filter with isRejected false

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${accountId}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${PconsumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}






















































































JD-TC-GetLeadByFilter-11

    [Documentation]             Get Lead By Filter - uid and reference

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&referenceNo-eq=${referenceNo2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-12

    [Documentation]             Get Lead By Filter - uid and losProduct

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&losProduct-eq=${losProduct}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-13

    [Documentation]             Get Lead By Filter - uid and internalProgress

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&internalProgress-eq=${internalProgress}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-14

    [Documentation]             Get Lead By Filter - uid and internalStatus

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&internalStatus-eq=${internalStatus}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-15

    [Documentation]             Get Lead By Filter - uid and consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&consumerId-eq=${consumerId}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}    []


JD-TC-GetLeadByFilter-16

    [Documentation]             Get Lead By Filter - uid and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&consumerFirstName-eq=${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-17

    [Documentation]             Get Lead By Filter - uid and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-18

    [Documentation]             Get Lead By Filter - uid and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-19

    [Documentation]             Get Lead By Filter - uid and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&isConverted-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-20

    [Documentation]             Get Lead By Filter - uid and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   uid-eq=${lead_uid2}&isRejected-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}    []


JD-TC-GetLeadByFilter-21

    [Documentation]             Get Lead By Filter - two leads referenceNo

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo},${referenceNo2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-22

    [Documentation]             Get Lead By Filter - referenceNo and losProduct

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&losProduct-eq=${losProduct}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-23

    [Documentation]             Get Lead By Filter - referenceNo and internalProgress

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&internalProgress-eq=${internalProgress2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-24

    [Documentation]             Get Lead By Filter - referenceNo and internalStatus

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&internalStatus-eq=${internalStatus2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-25

    [Documentation]             Get Lead By Filter - referenceNo and consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&consumerId-eq=${consumerId2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-26

    [Documentation]             Get Lead By Filter - referenceNo and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&consumerFirstName-eq=${consumerFirstName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}    []


JD-TC-GetLeadByFilter-27

    [Documentation]             Get Lead By Filter - referenceNo and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-28

    [Documentation]             Get Lead By Filter - referenceNo and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-29

    [Documentation]             Get Lead By Filter - referenceNo and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-30

    [Documentation]             Get Lead By Filter - referenceNo and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   referenceNo-eq=${referenceNo2}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-31

    [Documentation]             Get Lead By Filter - two losProduct

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct},${losProduct}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-32

    [Documentation]             Get Lead By Filter - losProduct and internalProgress

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&internalProgress-eq=${internalProgress2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-33

    [Documentation]             Get Lead By Filter - losProduct and internalStatus

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&internalStatus-eq=${internalStatus2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-34

    [Documentation]             Get Lead By Filter - losProduct and consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&consumerId-eq=${consumerId2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-35

    [Documentation]             Get Lead By Filter - losProduct and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&consumerFirstName-eq=${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-36

    [Documentation]             Get Lead By Filter - losProduct and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-37

    [Documentation]             Get Lead By Filter - losProduct and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-38

    [Documentation]             Get Lead By Filter - losProduct and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-39

    [Documentation]             Get Lead By Filter - losProduct and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   losProduct-eq=${losProduct}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-40

    [Documentation]             Get Lead By Filter - both internalProgress

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress},${internalProgress2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-41

    [Documentation]             Get Lead By Filter - internalProgress and internalStatus

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&internalStatus-eq=${internalStatus2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-42

    [Documentation]             Get Lead By Filter - internalProgress and consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&consumerId-eq=${consumerId2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-43

    [Documentation]             Get Lead By Filter - internalProgress and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&consumerFirstName-eq=${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-44

    [Documentation]             Get Lead By Filter - internalProgress and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-45

    [Documentation]             Get Lead By Filter - internalProgress and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-46

    [Documentation]             Get Lead By Filter - internalProgress and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress2}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-47

    [Documentation]             Get Lead By Filter - internalProgress and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalProgress-eq=${internalProgress}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-48

    [Documentation]             Get Lead By Filter - both internalStatus

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus},${internalStatus2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-49

    [Documentation]             Get Lead By Filter - internalStatus and consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus2}&consumerId-eq=${consumerId2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-50

    [Documentation]             Get Lead By Filter - internalStatus and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus2}&consumerFirstName-eq=${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-51

    [Documentation]             Get Lead By Filter - internalStatus and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-52

    [Documentation]             Get Lead By Filter - internalStatus and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-53

    [Documentation]             Get Lead By Filter - internalStatus and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus2}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-54

    [Documentation]             Get Lead By Filter - internalStatus and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   internalStatus-eq=${internalStatus}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}



JD-TC-GetLeadByFilter-55

    [Documentation]             Get Lead By Filter - both consumerId

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId},${consumerId2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-56

    [Documentation]             Get Lead By Filter - consumerId and consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId2}&consumerFirstName-eq=${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-57

    [Documentation]             Get Lead By Filter - consumerId and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-58

    [Documentation]             Get Lead By Filter - consumerId and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-59

    [Documentation]             Get Lead By Filter - consumerId and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId2}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-60

    [Documentation]             Get Lead By Filter - consumerId and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerId-eq=${consumerId2}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-61

    [Documentation]             Get Lead By Filter - both lead consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName},${consumerFirstName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-62

    [Documentation]             Get Lead By Filter - consumerFirstName and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName2}&consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-63

    [Documentation]             Get Lead By Filter - consumerFirstName and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-64

    [Documentation]             Get Lead By Filter - consumerFirstName and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-65

    [Documentation]             Get Lead By Filter - consumerFirstName and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName2}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-66

    [Documentation]             Get Lead By Filter - consumerLastName and consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName},${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-67

    [Documentation]             Get Lead By Filter - consumerLastName and createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName2}&createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-68

    [Documentation]             Get Lead By Filter - consumerLastName and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-69

    [Documentation]             Get Lead By Filter - consumerLastName and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName2}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}


JD-TC-GetLeadByFilter-70

    [Documentation]             Get Lead By Filter - both createdDate

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   createdDate-eq=${createdDate2},${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-71

    [Documentation]             Get Lead By Filter - createdDate and isConverted

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   createdDate-eq=${createdDate}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-72

    [Documentation]             Get Lead By Filter - createdDate and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   createdDate-eq=${createdDate2}&isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-73

    [Documentation]             Get Lead By Filter - isConverted and isRejected

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   isRejected-eq=${boolean[0]}&isConverted-eq=${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}     []


JD-TC-GetLeadByFilter-74

    [Documentation]             Get Lead By Filter - consumerFirstName or consumerLastName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   or=consumerFirstName-eq=${consumerFirstName2},consumerLastName-eq=${consumerLastName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-75

    [Documentation]             Get Lead By Filter - both consumerFirstName

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   or=consumerFirstName-eq=${consumerFirstName2},${consumerFirstName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

    Should Be Equal As Strings    ${resp.json()[1]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[1]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[1]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[1]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[1]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[1]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[1]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['gender']}               ${gender}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[1]['consumerKyc']['consumerEmail']}        ${consumerEmail}


JD-TC-GetLeadByFilter-76

    [Documentation]             Get Lead By Filter - consumerFirstName or Last name

    ${resp}=    Send Otp For Login    ${PconsumerPhone}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
  
    ${resp}=    Verify Otp For Login   ${PconsumerPhone}   12  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable   ${token}  ${resp.json()['token']}

    ${resp}=  Customer Logout   
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
   
    ${resp}=    ProviderConsumer Login with token    ${PconsumerPhone}    ${accountId}    ${token}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    PC Get Lead By Filter LOS   or=consumerFirstName-eq=${consumerFirstName2},consumerLastName-eq=${consumerLastName2}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid2}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${gender2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone2}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail2}

JD-TC-GetLeadByFilter-UH1

    [Documentation]             Get Lead By Filter - without login

    ${resp}=    PC Get Lead By Filter LOS
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   419
    Should Be Equal As Strings    ${resp.json()}   ${SESSION_EXPIRED}