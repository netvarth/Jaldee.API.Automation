*** Settings ***

Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Lead Manager
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
Variables         /ebs/TDD/varfiles/hl_providers.py

*** Variables ***

${jpgfile}      /ebs/TDD/uploadimage.jpg
${fileSize}     0.00458
${order}        0

*** Test Cases ***

JD-TC-Update_Stage-1

    [Documentation]   Update Stage

    ${resp}=  Encrypted Provider Login  ${PUSERNAME100}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}
    Set Suite Variable      ${pid}          ${decrypted_data['id']}
    Set Suite Variable      ${pdrname}      ${decrypted_data['userName']}

    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    ${tz}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    Set Suite Variable  ${tz}
    ${parking}   Random Element   ${parkingType}
    ${24hours}    Random Element    ['True','False']
    ${desc}=   FakerLibrary.sentence
    ${url}=   FakerLibrary.url
    ${sTime}=  add_timezone_time  ${tz}  0  15  
    Set Suite Variable   ${sTime}
    ${eTime}=  add_timezone_time  ${tz}  0  45  
    Set Suite Variable   ${eTime}
    
    ${DAY1}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY1} 

    ${resp}=    Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${accountId}        ${resp.json()['id']}
    Set Suite Variable    ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    IF  '${resp.json()['enableCrmLead']}'=='${bool[0]}'

        ${resp}=    Enable Disable CRM Lead  ${toggle[0]}
        Log  ${resp.json()}
        Should Be Equal As Strings    ${resp.status_code}    200

    END

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable      ${lid}      ${resp.json()[0]['id']}
    Set Suite Variable      ${place}    ${resp.json()[0]['place']}

    ${locid}=     Create Dictionary  id=${lid}
    ${loc_id}=  Create List   ${locid}

    ${typeName1}=    FakerLibrary.Name
    Set Suite Variable      ${typeName1}

    ${resp}=    Create Lead Product  ${typeName1}  ${productEnum[0]}  
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable      ${lpid}     ${resp.json()} 

    ${resp}=    Get Lead Product By Uid  ${lpid}
    Log  ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}      200

    ${ChannelName1}=    FakerLibrary.Name
    Set Suite Variable      ${ChannelName1}
    
    ${crmLeadProductTypeDto}=   Create Dictionary   uid=${lpid}
    Set Suite Variable      ${crmLeadProductTypeDto}

    # .... Attachments ......

    ${resp}=            db.getType  ${jpgfile} 
    Log  ${resp}
    ${fileType}=                    Get From Dictionary       ${resp}    ${jpgfile} 
    Set Suite Variable              ${fileType}
    ${caption}=                     Fakerlibrary.Sentence
    Set Suite Variable              ${caption}

    ${resp}    upload file to temporary location    ${file_action[0]}    ${pid}    ${ownerType[0]}    ${pdrname}    ${jpgfile}    ${fileSize}    ${caption}    ${fileType}    ${EMPTY}    ${order}
    Log  ${resp.content}
    Should Be Equal As Strings      ${resp.status_code}    200 
    Set Suite Variable              ${driveId}    ${resp.json()[0]['driveId']}

    ${resp}    change status of the uploaded file    ${QnrStatus[1]}    ${driveId}
    Log  ${resp.content}
    Should Be Equal As Strings      ${resp.status_code}    200

    ${attachments}=    Create Dictionary   action=${file_action[0]}  fileName=${jpgfile}  fileSize=${fileSize}  fileType=${fileType}  order=${order}    driveId=${driveId}
    Log  ${attachments}
    ${attachments}=  Create List    ${attachments}
    Set Suite Variable              ${attachments}

    ${resp}=    Create Lead Channel  ${ChannelName1}  ${leadchannel[0]}  ${crmLeadProductTypeDto}  locationDtos=${loc_id}  attachments=${attachments}
    Log  ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}      200
    Set Suite Variable      ${clid}     ${resp.json()} 

    ${resp}=    Get Lead Channel By Uid  ${clid}
    Log  ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}     200

    ${firstName_n}=   generate_firstname
    ${lastName_n}=    FakerLibrary.lastName
    Set Suite Variable      ${firstName_n}
    Set Suite Variable      ${lastName_n}

    ${resp}=    Create Lead Consumer  ${firstName_n}  ${lastName_n}  phone=${CUSERNAME14}  countryCode=${countryCodes[0]}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite variable   ${con_id}   ${resp.json()}

    ${resp}=    Get Lead Consumer  ${con_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}             200

    ${resp}=    Create Crm Lead  ${clid}  ${pid}  ${lid}  consumerUid=${con_id}  
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200
    Set Suite variable           ${crm_lead_id}          ${resp.json()}

    ${resp}=    Get Crm Lead   ${crm_lead_id} 
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

    ${user1}=  Create Sample User 
    Set suite Variable                    ${user1}
    
    ${resp}=  Get User By Id            ${user1}
    Log   ${resp.json()}
    Should Be Equal As Strings          ${resp.status_code}  200
    Set Suite Variable  ${user1_id}     ${resp.json()['id']}

    ${stage}=   generate_firstname

    ${resp}=    Create Stage  ${stage}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200
    Set Suite variable           ${stage_id}            ${resp.json()}

    ${resp}=    Get Stage By Id  ${stage_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

    ${stage2}=   generate_firstname
    Set Suite Variable      ${stage2}

    ${resp}=    Update stage  ${stage_id}  ${stage2}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

    ${resp}=    Get Stage By Id  ${stage_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

JD-TC-Update_Stage-2

    [Documentation]   Update Stage - updating stage name as empty

    ${resp}=  Encrypted Provider Login  ${PUSERNAME100}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Update stage  ${stage_id}  ${empty}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

JD-TC-Update_Stage-3

    [Documentation]   Update Stage - updating stage name bellow 3 digit

    ${resp}=  Encrypted Provider Login  ${PUSERNAME100}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${random_number}=    Random Number 	       digits=2

    ${resp}=    Update stage  ${stage_id}  ${random_number}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

JD-TC-Update_Stage-4

    [Documentation]   Update Stage - updating stage name above 100 digit

    ${resp}=  Encrypted Provider Login  ${PUSERNAME100}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${random_number}=    Random Number 	       digits=101

    ${resp}=    Update stage  ${stage_id}  ${random_number}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200

JD-TC-Update_Stage-5

    [Documentation]   Update Stage - stage id is invalid

    ${resp}=  Encrypted Provider Login  ${PUSERNAME100}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${inv}=     Random Int  min=111  max=999

    ${resp}=    Update stage  ${inv}  ${stage2}  ${crm_lead_id}  ${user1_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}     200