*** Settings ***
Suite Teardown     Delete All Sessions
Test Teardown      Delete All Sessions
Force Tags         LOS Lead
Library            Collections
Library            String
Library            json
Library            FakerLibrary
Library            /ebs/TDD/db.py
Library            /ebs/TDD/excelfuncs.py
Resource           /ebs/TDD/ProviderKeywords.robot
Resource           /ebs/TDD/ConsumerKeywords.robot
Resource           /ebs/TDD/ProviderPartnerKeywords.robot
Variables          /ebs/TDD/varfiles/providers.py
Variables          /ebs/TDD/varfiles/consumerlist.py 
Variables          /ebs/TDD/varfiles/musers.py
Variables          /ebs/TDD/varfiles/hl_musers.py

*** Variables ***

${losProduct}                    CDL
${aadhaar}                       555555555555
${pan}                           5555555555
${bankAccountNo}                 55555555555
${bankIfsc}                      55555555555

*** Test Cases ***

JD-TC-GetLeadByFilter-1

    [Documentation]             Get Lead By Filter

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}
    Set Test Variable  ${provider_id}  ${decrypted_data['id']}

    ${resp}=  Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings            ${resp.status_code}  200
    Set Suite Variable                    ${account_id1}       ${resp.json()['id']}

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

    ${Sname}=    FakerLibrary.name
    Set Suite Variable      ${Sname}

    ${resp}=    Create Lead Status LOS  ${Sname}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${status_id}      ${resp.json()['id']}

    ${resp}=    Get Lead Status LOS
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['id']}           ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['name']}         ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['status']}       ${toggle[0]}

    ${Pname}=    FakerLibrary.name
    Set Suite Variable      ${Pname}

    ${resp}=    Create Lead Progress LOS  ${Pname}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${progress_id}      ${resp.json()['id']}

    ${resp}=    Get Lead Progress LOS
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['id']}           ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['name']}         ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['status']}       ${toggle[0]}

    ${PH_Number}    Random Number 	       digits=5 
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable    ${consumerPhone}  555${PH_Number}

    ${resp}=  AddCustomer  ${consumerPhone}    
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  GetCustomer  phoneNo-eq=${consumerPhone}
    Log   ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}  200
    Set Suite Variable  ${consumerId}  ${resp.json()[0]['id']}

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
    Set Suite Variable      ${Pname}
    Set Suite Variable     ${consumerEmail}  ${consumerFirstName}.${test_mail}   
    ${permanentAddress1}=   FakerLibrary.address
    Set Suite Variable      ${permanentAddress1}
    ${permanentAddress2}=   FakerLibrary.address  
    Set Suite Variable      ${permanentAddress2}
    ${nomineeName}=     FakerLibrary.first_name
    Set Suite Variable      ${nomineeName}

    ${resp}=    Create Lead LOS  ${leadchannel[0]}  ${losProduct}  ${status_id}  ${Sname}  ${progress_id}  ${Pname}  ${requestedAmount}  ${description}  ${consumerId}  ${consumerFirstName}  ${consumerLastName}  ${dob}  ${Genderlist[1]}  ${countryCodes[1]}  ${consumerPhone}  ${consumerEmail}  ${aadhaar}  ${pan}  ${bankAccountNo}  ${bankIfsc}  ${permanentAddress1}  ${permanentAddress2}  ${permanentDistrict}  ${permanentState}  ${permanentPin}  ${NomineeType[2]}  ${nomineeName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${lead_uid}      ${resp.json()['uid']}

    ${resp}=    Get Lead LOS   ${lead_uid}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable      ${kycid}            ${resp.json()['consumerKyc']['id']}
    Set Suite Variable      ${referenceNo}      ${resp.json()['referenceNo']}
    Set Suite Variable      ${createdDate}      ${resp.json()['createdDate']}
    Should Be Equal As Strings    ${resp.json()['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['leadUid']}              ${lead_uid}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['consumerEmail']}        ${consumerEmail}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['permanentAddress1']}    ${permanentAddress1}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['permanentAddress2']}    ${permanentAddress2}
    Should Be Equal As StringS    ${resp.json()['consumerKyc']['permanentDistrict']}    ${permanentDistrict}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['permanentState']}       ${permanentState}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['permanentPin']}         ${permanentPin}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['aadhaar']}              ${aadhaar}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['pan']}                  ${pan}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['bankAccountNo']}        ${bankAccountNo}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['bankIfsc']}             ${bankIfsc}
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['nomineeType']}          ${NomineeType[2]}  
    Should Be Equal As Strings    ${resp.json()['consumerKyc']['nomineeName']}          ${nomineeName}

    ${resp}=    Get Lead By Filter LOS
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-2

    [Documentation]             Get Lead By Filter with uid

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   uid-eq=${lead_uid}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-3

    [Documentation]             Get Lead By Filter with referenceNo

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   referenceNo-eq=${referenceNo}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-4

    [Documentation]             Get Lead By Filter with losProduct

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   losProduct-eq=${losProduct}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-5

    [Documentation]             Get Lead By Filter with consumerId

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   consumerId-eq=${consumerId}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-6

    [Documentation]             Get Lead By Filter with consumerFirstName

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   consumerFirstName-eq=${consumerFirstName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-7

    [Documentation]             Get Lead By Filter with consumerLastName

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   consumerLastName-eq=${consumerLastName}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-8

    [Documentation]             Get Lead By Filter with createdDate

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   createdDate-eq=${createdDate}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-9

    [Documentation]             Get Lead By Filter with isConverted false

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   isConverted-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}

JD-TC-GetLeadByFilter-10

    [Documentation]             Get Lead By Filter with isRejected false

    ${resp}=   Encrypted Provider Login  ${PUSERNAME30}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Lead By Filter LOS   isRejected-eq=${boolean[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()[0]['uid']}                                 ${lead_uid}
    Should Be Equal As Strings    ${resp.json()[0]['account']}                             ${account_id1}
    Should Be Equal As Strings    ${resp.json()[0]['channel']}                             ${leadchannel[0]}
    Should Be Equal As Strings    ${resp.json()[0]['losProduct']}                          ${losProduct}
    Should Be Equal As Strings    ${resp.json()[0]['status']['id']}                        ${status_id}
    Should Be Equal As Strings    ${resp.json()[0]['status']['name']}                      ${Sname}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['id']}                      ${progress_id}
    Should Be Equal As Strings    ${resp.json()[0]['progress']['name']}                    ${Pname}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerId']}           ${consumerId}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerFirstName']}    ${consumerFirstName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerLastName']}     ${consumerLastName}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['dob']}                  ${dob}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['gender']}               ${Genderlist[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhoneCode']}    ${countryCodes[1]}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerPhone']}        ${consumerPhone}
    Should Be Equal As Strings    ${resp.json()[0]['consumerKyc']['consumerEmail']}        ${consumerEmail}