
*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Teleservice
Library           Collections
Library           String
Library           json
Library           requests
Library           FakerLibrary
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_providers.py


*** Variables ***

${ZOOM_url}    https://zoom.us/j/{}?pwd=THVLcTBZa2lESFZQbU9DQTQrWUxWZz09

@{service_duration}  1  2  3   4   5

***Keywords***


Get Billable Subdomain
    [Arguments]   ${domain}  ${jsondata}  ${posval}  
    ${length}=  Get Length  ${jsondata.json()[${posval}]['subDomains']}
    FOR  ${pos}  IN RANGE  ${length}
            Set Suite Variable  ${subdomain}  ${jsondata.json()[${posval}]['subDomains'][${pos}]['subDomain']}
            ${resp}=   Get Sub Domain Settings    ${domain}    ${subdomain}
            Should Be Equal As Strings    ${resp.status_code}    200
            Exit For Loop IF  '${resp.json()['serviceBillable']}' == '${bool[1]}'
    END
    RETURN  ${subdomain}  ${resp.json()['serviceBillable']}



Get Non Billable Subdomain
    [Arguments]   ${domain}  ${jsondata}  ${posval}  
    ${length}=  Get Length  ${jsondata.json()[${posval}]['subDomains']}
    FOR  ${pos}  IN RANGE  ${length}
            Set Test Variable  ${subdomain}  ${jsondata.json()[${posval}]['subDomains'][${pos}]['subDomain']}
            ${resp}=   Get Sub Domain Settings    ${domain}    ${subdomain}
            Should Be Equal As Strings    ${resp.status_code}    200
            Exit For Loop IF  '${resp.json()['serviceBillable']}' == '${bool[0]}'
    END
    RETURN  ${subdomain}  ${resp.json()['serviceBillable']}






*** Test Cases ***
JD-TC-TeleserviceWaitlist-(Billable Subdomain)-1
    [Documentation]  Create Teleservice meeting request for waitlist in WhatsApp (WALK-IN CHECKIN)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${account_id}=  get_acc_id  ${HLPUSERNAME27}
    Set Suite Variable  ${account_id}

    ${fname}=  generate_firstname
    ${lname}=  FakerLibrary.last_name
    Set Test Variable  ${pc_emailid1}  ${fname}${C_Email}.${test_mail}

    ${resp}=  AddCustomer  ${CUSERNAME0}    firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  email=${pc_emailid1}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${resp}=  Send Otp For Login    ${CUSERNAME0}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}
    ${resp}=  Verify Otp For Login   ${CUSERNAME0}   ${OtpPurpose['Authentication']}    JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    # ${resp}=   Consumer Login  ${CUSERNAME0}  ${PASSWORD}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # ${DAY}=  db.get_date_by_timezone  ${tz}    
    ${firstname}=  FakerLibrary.name
    ${lastname}=  FakerLibrary.last_name
    ${dob}=  FakerLibrary.Date
    ${gender}    Random Element    ${Genderlist}
    ${resp}=    Add FamilyMember For ProviderConsumer     ${firstname}  ${lastname}  ${dob}  ${gender}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200  
    Set Suite Variable  ${cidfor}   ${resp.json()}

    ${UserZOOM_id0}=  Format String  ${ZOOM_url}  ${CUSERNAME0}

    Set Suite Variable  ${ZOOM_id2}    ${UserZOOM_id0}
    Set Suite Variable  ${WHATSAPP_id2}   ${countryCodes[0]}${CUSERNAME0}

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${decrypted_data}=  db.decrypt_data  ${resp.content}
    Log  ${decrypted_data}

    # clear_customer   ${HLPUSERNAME27}

    # ${list}=  Create List  1  2  3  4  5  6  7
    # Set Suite Variable  ${list}  ${list}
    # ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    # ${tz}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    # Set Suite Variable  ${tz}
    
    ${resp}=  Get Waitlist Settings
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['enabledWaitlist']}==${bool[0]}   
        ${resp}=   Enable Waitlist
        Should Be Equal As Strings  ${resp.status_code}  200
    END

    ${ZOOM_id0}=  Format String  ${ZOOM_url}  ${HLPUSERNAME27}
    Set Suite Variable   ${ZOOM_id0}

    ${instructions1}=   FakerLibrary.sentence
    ${instructions2}=   FakerLibrary.sentence

    ${VirtualcallingMode1}=   Create Dictionary   callingMode=${CallingModes[0]}   value=${ZOOM_id0}   status=ACTIVE    instructions=${instructions1} 
    ${VirtualcallingMode2}=   Create Dictionary   callingMode=${CallingModes[1]}   value=${HLPUSERNAME27}   countryCode=${countryCodes[0]}  status=ACTIVE    instructions=${instructions2} 
    ${vcm1}=  Create List  ${VirtualcallingMode1}   ${VirtualcallingMode2}

    ${resp}=  Update Virtual Calling Mode   ${vcm1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Virtual Calling Mode
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['callingMode']}     ${CallingModes[0]}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['value']}           ${ZOOM_id0}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['status']}          ACTIVE
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['instructions']}    ${instructions1}

    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['callingMode']}     ${CallingModes[1]}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['value']}           ${HLPUSERNAME27}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['status']}          ACTIVE
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['instructions']}    ${instructions2}

    # ${PUSERPH_id0}=  Evaluate  ${PUSERNAME}+50505
    Set Test Variable  ${callingMode1}     ${CallingModes[1]}
    # Set Test Variable  ${ModeId1}          ${PUSERPH_id0}
    Set Test Variable  ${ModeId1}          ${HLPUSERNAME27}
    Set Test Variable  ${ModeStatus1}      ACTIVE
    ${Description1}=    FakerLibrary.sentence
    ${VScallingMode1}=   Create Dictionary   callingMode=${callingMode1}   value=${ModeId1}   countryCode=${countryCodes[0]}  status=${ModeStatus1}   instructions=${Description1}
    ${virtualCallingModes1}=  Create List  ${VScallingMode1}

    ${Total1}=   Random Int   min=100   max=500
    ${Total1}=  Convert To Number  ${Total1}  1
    ${SERVICE1}=    FakerLibrary.word
    ${description}=    FakerLibrary.word
    Set Test Variable  ${vstype}  ${vservicetype[0]}
    ${resp}=  Create Service  ${SERVICE1}  ${description}  ${service_duration[1]}  ${bool[0]}  ${Total1}  ${bool[0]}   serviceType=${ServiceType[0]}  virtualServiceType=${vstype}  virtualCallingModes=${virtualCallingModes1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200 
    # ${resp}=  Create virtual Service  ${SERVICE1}   ${description}   5   ${status[0]}   ${btype}    ${bool[1]}    ${notifytype[2]}  ${EMPTY}  ${Total1}  ${bool[0]}   ${bool[0]}   ${vstype}   ${virtualCallingModes1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 
    Set Suite Variable  ${p1_s1}  ${resp.json()} 

    ${resp}=   Get Service By Id  ${p1_s1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
   
    ${ZOOM_Pid0}=  Format String  ${ZOOM_url}  ${HLPUSERNAME27}
    Set Suite Variable   ${ZOOM_Pid0}

    Set Test Variable  ${callingMode2}     ${CallingModes[0]}
    Set Test Variable  ${ModeId2}          ${ZOOM_Pid0}
    Set Test Variable  ${ModeStatus2}      ACTIVE
    ${Description2}=    FakerLibrary.sentence
    ${VScallingMode2}=   Create Dictionary   callingMode=${callingMode2}   value=${ModeId2}   status=${ModeStatus2}   instructions=${Description2}
    ${virtualCallingModes2}=  Create List  ${VScallingMode2}

    ${Total2}=   Random Int   min=100   max=500
    ${Total2}=  Convert To Number  ${Total2}  1
    ${SERVICE2}=    FakerLibrary.first_name
    ${description2}=    FakerLibrary.word
    Set Test Variable  ${vstype2}  ${vservicetype[1]}
    ${resp}=  Create Service  ${SERVICE2}  ${description2}  ${service_duration[1]}  ${bool[0]}  ${Total2}  ${bool[0]}   serviceType=${ServiceType[0]}  virtualServiceType=${vstype2}  virtualCallingModes=${virtualCallingModes2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200 
    # ${resp}=  Create virtual Service  ${SERVICE2}   ${description2}   5   ${status[0]}   ${btype}    ${bool[1]}    ${notifytype[2]}  ${EMPTY}  ${Total2}  ${bool[0]}   ${bool[0]}   ${vstype2}   ${virtualCallingModes2}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200 
    Set Suite Variable  ${p1_s2}  ${resp.json()} 
    
    ${resp}=   Get Service By Id  ${p1_s2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${resp}=  Get Service
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${p1_s3}   ${resp.json()[2]['id']}
    Set Suite Variable   ${P1SERVICE3}   ${resp.json()[2]['name']}

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${p1_l1}=  Create Sample Location
        ${resp}=   Get Location ById  ${p1_l1}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Suite Variable  ${tz}  ${resp.json()['timezone']}
    ELSE
        Set Suite Variable  ${p1_l1}  ${resp.json()[0]['id']}
        Set Suite Variable  ${tz}  ${resp.json()[0]['timezone']}
    END 

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${sTime1}=  add_timezone_time  ${tz}  0  30  
    ${eTime1}=  add_timezone_time  ${tz}  0  45  
    ${p1queue1}=    FakerLibrary.word
    ${capacity}=  FakerLibrary.Numerify  %%
    ${list}=  Create List  1  2  3  4  5  6  7
    ${resp}=  Create Queue  ${p1queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime1}  ${eTime1}  1  ${capacity}  ${p1_l1}  ${p1_s1}  ${p1_s2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${queueId}  ${resp.json()}
    
    ${resp}=    Enable Search Data
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  AddCustomer  ${CUSERNAME2}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${pcid0}  ${resp.json()}

    ${resp}=  GetCustomer  phoneNo-eq=${CUSERNAME2}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable  ${cid}  ${resp.json()[0]['id']}
    ${virtualService}=  Create Dictionary   ${CallingModes[1]}=${WHATSAPP_id2}
    ${desc}=   FakerLibrary.word
    Set Suite Variable  ${desc}
    ${resp}=  Provider Add To WL With Virtual Service  ${pcid0}  ${p1_s1}  ${queueId}  ${DAY}  ${desc}  ${bool[1]}  ${waitlistMode[2]}  ${virtualService}   ${pcid0}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid1}  ${wid[0]}
    ${resp}=  Get Waitlist By Id  ${wid1} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1  waitlistedBy=${waitlistedby[1]}   personsAhead=0  onlineRequest=${bool[0]}   waitlistMode=${waitlistMode[2]}   
    # Should Be Equal As Strings  ${resp.json()['service']['name']}                 ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}                   ${p1_s1}
    Should Be Equal As Strings  ${resp.json()['consumer']['id']}                  ${pcid0}
    Should Be Equal As Strings  ${resp.json()['waitlistingFor'][0]['id']}         ${pcid0}

    ${resp}=  Create Waitlist Meeting Request   ${wid1}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid1}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid1}   ${CallingModes[1]}   ${account_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action   ${waitlist_actions[2]}  ${wid1}  cancelReason=${waitlist_cancl_reasn[4]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-TeleserviceWaitlist-(Billable Subdomain)-2
    [Documentation]  Create Teleservice meeting request for waitlist in Zoom (WALK-IN CHECKIN)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${accId}=  get_acc_id  ${HLPUSERNAME27}
    Set Suite Variable  ${accId}  ${accId} 

    ${resp}=  Get Service
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${p1_s3}   ${resp.json()[2]['id']}
    Set Test Variable   ${P1SERVICE3}   ${resp.json()[2]['name']}

    ${virtualService}=  Create Dictionary   ${CallingModes[0]}=${ZOOM_id2}
    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${desc1}=   FakerLibrary.word
    Set Suite Variable  ${desc}
    ${resp}=  Provider Add To WL With Virtual Service  ${pcid0}  ${p1_s2}  ${queueId}  ${DAY}  ${desc1}  ${bool[1]}  ${waitlistMode[2]}  ${virtualService}   ${pcid0}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid2}  ${wid[0]}
    ${resp}=  Get Waitlist By Id  ${wid2} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1    waitlistedBy=${waitlistedby[1]}   personsAhead=0  onlineRequest=${bool[0]}   waitlistMode=${waitlistMode[2]}   
    # Should Be Equal As Strings  ${resp.json()['service']['name']}                 ${P1SERVICE2}
    Should Be Equal As Strings  ${resp.json()['service']['id']}                   ${p1_s2}
    Should Be Equal As Strings  ${resp.json()['consumer']['id']}                  ${pcid0}
    Should Be Equal As Strings  ${resp.json()['waitlistingFor'][0]['id']}         ${pcid0}


    ${resp}=  Create Waitlist Meeting Request   ${wid2}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid2}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

     ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid2}    ${CallingModes[0]}   ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action   ${waitlist_actions[2]}  ${wid2}  cancelReason=${waitlist_cancl_reasn[4]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200



JD-TC-TeleserviceWaitlist-(Billable Subdomain)-UH1
    [Documentation]  Create Teleservice meeting request for waitlist in Zoom,WhatsApp,phone and Googlemeet (WALK-IN CHECKIN)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${accId}=  get_acc_id  ${HLPUSERNAME27}
    Set Suite Variable  ${accId}  ${accId} 

    ${resp}=  Get Service
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${p1_s3}   ${resp.json()[2]['id']}
    Set Test Variable   ${P1SERVICE3}   ${resp.json()[2]['name']}

    ${virtualService}=  Create Dictionary   ${CallingModes[1]}=${WHATSAPP_id2}
    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${desc1}=   FakerLibrary.word
    Set Suite Variable  ${desc}
    ${resp}=  Provider Add To WL With Virtual Service  ${pcid0}  ${p1_s1}  ${queueId}  ${DAY}  ${desc1}  ${bool[1]}  ${waitlistMode[2]}  ${virtualService}   ${pcid0}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid3}  ${wid[0]}
    ${resp}=  Get Waitlist By Id  ${wid3} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1    waitlistedBy=${waitlistedby[1]}   personsAhead=0  onlineRequest=${bool[0]}   waitlistMode=${waitlistMode[2]}   
    # Should Be Equal As Strings  ${resp.json()['service']['name']}                 ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}                   ${p1_s1}
    Should Be Equal As Strings  ${resp.json()['consumer']['id']}                  ${pcid0}
    Should Be Equal As Strings  ${resp.json()['waitlistingFor'][0]['id']}         ${pcid0}

    ${resp}=  Create Waitlist Meeting Request   ${wid3}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Get Waitlist Meeting Request    ${wid3}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Create Waitlist Meeting Request   ${wid3}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid3}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid3}   ${CallingModes[2]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Get Waitlist Meeting Request    ${wid3}    ${CallingModes[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Create Waitlist Meeting Request   ${wid3}   ${CallingModes[3]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Get Waitlist Meeting Request    ${wid3}    ${CallingModes[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"
    
    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid3}    ${CallingModes[1]}    ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action   ${waitlist_actions[2]}  ${wid3}  cancelReason=${waitlist_cancl_reasn[4]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-TeleserviceWaitlist-(Billable Subdomain)-3

    [Documentation]  Create Teleservice meeting request for waitlist in WhatsApp (ONLINE CHECKIN)

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${cid}=  get_id  ${CUSERNAME2}    

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${consumerNote1}=   FakerLibrary.word
    ${virtualService}=  Create Dictionary   ${CallingModes[1]}=${WHATSAPP_id2}
    ${resp}=  Consumer Add To WL With Virtual Service  ${accId}  ${queueId}  ${DAY}  ${p1_s1}  ${consumerNote1}  ${bool[0]}  ${virtualService}   0
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid4}  ${wid[0]}
    ${resp}=  Get consumer Waitlist By Id   ${wid4}  ${accId}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1   
    # Should Be Equal As Strings  ${resp.json()['service']['name']}  ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}  ${p1_s1}
    Should Be Equal As Strings  ${resp.json()['queue']['id']}  ${queueId}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid4}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid4}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid4}    ${CallingModes[1]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action    ${waitlist_actions[2]}  ${wid4}  cancelReason=${waitlist_cancl_reasn[4]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200



JD-TC-TeleserviceWaitlist-(Billable Subdomain)-4
    [Documentation]  Create Teleservice meeting request for waitlist in Zoom (ONLINE CHECKIN)

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${cid}=  get_id  ${CUSERNAME0}    

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${consumerNote1}=   FakerLibrary.word
    ${virtualService}=  Create Dictionary   ${CallingModes[0]}=${ZOOM_id2}
    ${resp}=  Consumer Add To WL With Virtual Service  ${accId}  ${queueId}  ${DAY}  ${p1_s2}  ${consumerNote1}  ${bool[0]}  ${virtualService}   0
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid5}  ${wid[0]}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  GetCustomer  phoneNo-eq=${CUSERNAME0}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${pcons_id}  ${resp.json()[0]['id']}

    # ${resp}=  Consumer Login  ${CUSERNAME0}  ${PASSWORD}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=    Send Otp For Login    ${CUSERNAME0}    ${pid}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200

    # ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    # ${resp}=    Verify Otp For Login   ${CUSERNAME0}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200
    # Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200 

    ${resp}=  Get consumer Waitlist By Id   ${wid5}  ${accId}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1  
    # Should Be Equal As Strings  ${resp.json()['service']['name']}  ${P1SERVICE2}
    Should Be Equal As Strings  ${resp.json()['service']['id']}  ${p1_s2}
    Should Be Equal As Strings  ${resp.json()['queue']['id']}  ${queueId}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid5}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid5}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid5}   ${CallingModes[0]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action   ${waitlist_actions[2]}  ${wid5}  cancelReason=${waitlist_cancl_reasn[4]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-TeleserviceWaitlist-(Billable Subdomain)-UH2

    [Documentation]  Create Teleservice meeting request for waitlist  in Zoom and WhatsApp (ONLINE CHECKIN)


    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${cid}=  get_id  ${CUSERNAME0}    

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${consumerNote1}=   FakerLibrary.word
    ${virtualService}=  Create Dictionary   ${CallingModes[0]}=${ZOOM_id2}
    ${resp}=  Consumer Add To WL With Virtual Service  ${accId}  ${queueId}  ${DAY}  ${p1_s2}  ${consumerNote1}  ${bool[0]}  ${virtualService}   0
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${wid6}  ${wid[0]}
    ${resp}=  Get consumer Waitlist By Id   ${wid6}  ${accId}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1    
    # Should Be Equal As Strings  ${resp.json()['service']['name']}  ${P1SERVICE2}
    Should Be Equal As Strings  ${resp.json()['service']['id']}  ${p1_s2}
    Should Be Equal As Strings  ${resp.json()['queue']['id']}  ${queueId}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid6}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request   ${wid6}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid6}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Get Waitlist Meeting Request    ${wid6}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid6}    ${CallingModes[0]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action    ${waitlist_actions[2]}  ${wid6}  cancelReason=${waitlist_cancl_reasn[4]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-TeleserviceWaitlist-(Billable Subdomain)-5

    [Documentation]   Create waitlist teleservice Zoom meeting request Which  is already created

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${cid}=  get_id  ${CUSERNAME0}    

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${consumerNote1}=   FakerLibrary.word
    ${virtualService}=  Create Dictionary   ${CallingModes[0]}=${ZOOM_id2}
    ${resp}=  Consumer Add To WL With Virtual Service  ${accId}  ${queueId}  ${DAY}  ${p1_s2}  ${consumerNote1}  ${bool[0]}  ${virtualService}   0
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid7}  ${wid[0]}
    ${resp}=  Get consumer Waitlist By Id   ${wid7}  ${accId}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1  
    # Should Be Equal As Strings  ${resp.json()['service']['name']}  ${P1SERVICE2}
    Should Be Equal As Strings  ${resp.json()['service']['id']}  ${p1_s2}
    Should Be Equal As Strings  ${resp.json()['queue']['id']}  ${queueId}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # step_1
    ${resp}=  Create Waitlist Meeting Request   ${wid7}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request   ${wid7}    ${CallingModes[0]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # step_2
    ${resp}=  Create Waitlist Meeting Request   ${wid7}   ${CallingModes[0]}  ${waitlistedby[1]}  ${waitlistedby[0]}
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request   ${wid7}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid7}   ${CallingModes[0]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action    ${waitlist_actions[2]}  ${wid7}  cancelReason=${waitlist_cancl_reasn[4]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

JD-TC-TeleserviceWaitlist-(Billable Subdomain)-6

    [Documentation]   Create waitlist teleservice Whatsapp meeting request Which  is already created

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${cid}=  get_id  ${CUSERNAME0}    

    ${DAY}=  db.get_date_by_timezone  ${tz}
    ${consumerNote1}=   FakerLibrary.word
    ${virtualService}=  Create Dictionary   ${CallingModes[1]}=${WHATSAPP_id2}
    ${resp}=  Consumer Add To WL With Virtual Service  ${accId}  ${queueId}  ${DAY}  ${p1_s1}  ${consumerNote1}  ${bool[0]}  ${virtualService}   0
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid8}  ${wid[0]}
    ${resp}=  Get consumer Waitlist By Id   ${wid8}  ${accId}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1  
    # Should Be Equal As Strings  ${resp.json()['service']['name']}  ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}  ${p1_s1}
    Should Be Equal As Strings  ${resp.json()['queue']['id']}  ${queueId}


    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # step_1
    ${resp}=  Create Waitlist Meeting Request   ${wid8}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request   ${wid8}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # step_2
    ${resp}=  Create Waitlist Meeting Request   ${wid8}   ${CallingModes[1]}  ${waitlistedby[1]}  ${waitlistedby[0]}
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request   ${wid8}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid8}   ${CallingModes[1]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Consumer Logout
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=   Encrypted Provider Login  ${HLPUSERNAME27}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Waitlist Action    ${waitlist_actions[2]}  ${wid8}  cancelReason=${waitlist_cancl_reasn[4]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

JD-TC-GetWaitlistMeetingDetails-UH3

    [Documentation]    Create waitlist teleservice meeting request  with invalid  waitlist id 
    
    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${INVALID_Wid}   0000
    ${resp}=   Get Waitlist Meeting Details   ${INVALID_Wid}   ${CallingModes[0]}  ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "Invalid waitlist uid"







# JD-TC-TeleserviceWaitlist-UH4
#     [Documentation]    Create waitlist teleservice meeting request  with invalid  Calling mode 
#     ${resp}=  Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD}
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200

#     ${resp}=  Create Waitlist Meeting Request   ${wid6}   ${CallingModes[5]}   ${waitlistedby[1]}
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  422
#     Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"





*** Comments ***
JD-TC-TeleserviceWaitlist-(Non billable Subdomain)-7
    [Documentation]  Create Teleservice meeting request for waitlist  in Zoom (Non billable Subdomain)
    ${PUSERPH2}=  Evaluate  ${PUSERNAME}+1081915
    Set Suite Variable   ${PUSERPH2}
    ${licid}  ${licname}=  get_highest_license_pkg
    Log  ${licid}
    Log  ${licname}
    ${domresp}=  Get BusinessDomainsConf
    Log  ${domresp.json()}
    Should Be Equal As Strings  ${domresp.status_code}  200
    Set Suite Variable  ${domresp}

    ${dlen}=  Get Length  ${domresp.json()}
    FOR  ${pos}  IN RANGE  ${dlen}  
        Set Test Variable  ${d2}  ${domresp.json()[${pos}]['domain']}
        ${sd2}  ${check}=  Get Non Billable Subdomain  ${d2}  ${domresp}  ${pos}  
        Set Test Variable   ${sd2}
        Exit For Loop IF     '${check}' == '${bool[0]}'

    END
    
    Log  ${d2}
    Log  ${sd2}

    ${firstname}=  FakerLibrary.first_name
    ${lastname}=  FakerLibrary.last_name
    ${address}=  FakerLibrary.address
    ${dob}=  FakerLibrary.Date
    ${gender}=    Random Element    ${Genderlist}
    ${resp}=  Account SignUp  ${firstname}  ${lastname}  ${None}  ${d2}  ${sd2}  ${PUSERPH2}  ${licid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Account Activation  ${PUSERPH2}  0
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings  "${resp.json()}"    "true"
    Append To File  ${EXECDIR}/data/TDD_Logs/numbers.txt  ${PUSERPH2}${\n}

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}
    ${resp}=  Account Set Credential  ${PUSERPH2}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${PUSERPH2}    JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=   Encrypted Provider Login  ${PUSERPH2}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${decrypted_data}=  db.decrypt_data  ${resp.content}
    Log  ${decrypted_data}
    Set Suite Variable  ${pid}  ${decrypted_data['id']}
    # Set Test Variable  ${pid}  ${resp.json()['id']}
    ${accId}=  get_acc_id  ${PUSERPH0}
    Set Suite Variable   ${accId}
    ${DAY1}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY1}  ${DAY1}
    ${list}=  Create List  1  2  3  4  5  6  7
    Set Suite Variable  ${list}  ${list}
    ${ph1}=  Evaluate  ${PUSERPH2}+1000000000
    ${ph2}=  Evaluate  ${PUSERPH2}+2000000000
    ${views}=  Random Element    ${Views}
    ${name1}=  FakerLibrary.name
    ${name2}=  FakerLibrary.name
    ${name3}=  FakerLibrary.name
    ${ph_nos1}=  Phone Numbers  ${name1}  PhoneNo  ${ph1}  ${views}
    ${ph_nos2}=  Phone Numbers  ${name2}  PhoneNo  ${ph2}  ${views}
    ${emails1}=  Emails  ${name3}  Email  ${P_Email}${PUSERPH2}.${test_mail}  ${views}
    ${bs}=  FakerLibrary.bs
    ${companySuffix}=  FakerLibrary.companySuffix
    # ${city}=   FakerLibrary.state
    # ${latti}=  get_latitude
    # ${longi}=  get_longitude
    # ${postcode}=  FakerLibrary.postcode
    # ${address}=  get_address
    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    ${tz}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    Set Suite Variable  ${tz}
    ${parking}   Random Element   ${parkingType}
    ${24hours}    Random Element    ${bool}
    ${desc}=   FakerLibrary.sentence
    ${url}=   FakerLibrary.url
    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${sTime}=  add_timezone_time  ${tz}  0  15  
    Set Suite Variable   ${sTime}
    ${eTime}=  add_timezone_time  ${tz}  0  45  
    Set Suite Variable   ${eTime}
    ${resp}=  Update Business Profile with schedule   ${bs}  ${desc}   ${companySuffix}  ${city}   ${longi}  ${latti}  ${url}  ${parking}  ${24hours}  ${recurringtype[1]}  ${list}  ${DAY1}  ${EMPTY}  ${EMPTY}  ${sTime}  ${eTime}  ${postcode}  ${address}  ${ph_nos1}  ${ph_nos2}  ${emails1}  ${EMPTY}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${fields}=   Get subDomain level Fields  ${d2}  ${sd2}
    Log  ${fields.json()}
    Should Be Equal As Strings    ${fields.status_code}   200

    ${virtual_fields}=  get_Subdomainfields  ${fields.json()}

    ${resp}=  Update Subdomain_Level  ${virtual_fields}  ${sd2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get specializations Sub Domain  ${d2}  ${sd2}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${spec}=  get_Specializations  ${resp.json()}
    ${resp}=  Update Specialization  ${spec}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    Set Test Variable  ${email_id}  ${P_Email}${PUSERPH2}.${test_mail}

    ${resp}=  Update Email   ${p_id}   ${firstname}  ${lastname}   ${email_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Settings
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['enabledWaitlist']}==${bool[0]}   
        ${resp}=   Enable Waitlist
        Should Be Equal As Strings  ${resp.status_code}  200
    END

    ${resp}=  Get Waitlist Settings
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enabledWaitlist']}   ${bool[1]}
    sleep   01s

    # ${resp}=  Enable Disable Virtual Service  Enable
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${ZOOM_id2}=  Format String  ${ZOOM_url}  ${PUSERPH2}
    Set Suite Variable   ${ZOOM_id2}

    ${instructions1}=   FakerLibrary.sentence
    ${instructions2}=   FakerLibrary.sentence

    ${VirtualcallingMode1}=   Create Dictionary   callingMode=${CallingModes[0]}   value=${ZOOM_id2}   status=ACTIVE    instructions=${instructions1} 
    ${VirtualcallingMode2}=   Create Dictionary   callingMode=${CallingModes[1]}   value=${PUSERPH2}   countryCode=${countryCodes[0]}  status=ACTIVE    instructions=${instructions2} 
    ${vcm1}=  Create List  ${VirtualcallingMode1}   ${VirtualcallingMode2}

    ${resp}=  Update Virtual Calling Mode   ${vcm1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Virtual Calling Mode
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['callingMode']}     ${CallingModes[0]}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['value']}           ${ZOOM_id2}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['status']}          ACTIVE
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][0]['instructions']}    ${instructions1}

    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['callingMode']}     ${CallingModes[1]}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['value']}           ${PUSERPH2}
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['status']}          ACTIVE
    Should Be Equal As Strings  ${resp.json()['virtualCallingModes'][1]['instructions']}    ${instructions2}



    ${PUSERPH_id2}=  Evaluate  ${PUSERNAME}+10101
    ${ZOOM_Pid2}=  Format String  ${ZOOM_url}  ${PUSERPH_id2}
    Set Suite Variable   ${ZOOM_Pid2}



    Set Test Variable  ${callingMode1}     ${CallingModes[0]}
    Set Test Variable  ${ModeId1}          ${ZOOM_Pid2}
    Set Test Variable  ${ModeStatus1}      ACTIVE
    ${Description1}=    FakerLibrary.sentence
    ${VirtualcallingMode1}=   Create Dictionary   callingMode=${callingMode1}   value=${ModeId1}   status=${ModeStatus1}   instructions=${Description1}
    ${virtualCallingModes}=  Create List  ${VirtualcallingMode1}
    

    ${min_pre}=   Random Int   min=10   max=50
    ${Total}=   Random Int   min=100   max=500
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${Total}=  Convert To Number  ${Total}  1
    ${SERVICE1}=    FakerLibrary.word
    ${description}=    FakerLibrary.word
    Set Test Variable  ${vstype}  ${vservicetype[1]}
    ${resp}=  Create virtual Service  ${SERVICE1}   ${description}   5   ${status[0]}   ${btype}    ${bool[1]}    ${notifytype[2]}  ${min_pre}  ${Total}  ${bool[0]}   ${bool[0]}   ${vstype}   ${virtualCallingModes}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    Set Suite Variable  ${Service_id1}  ${resp.json()} 
    ${resp}=   Get Service By Id  ${Service_id1}
    Should Be Equal As Strings  ${resp.status_code}  200
    Log  ${resp.json()}
    Verify Response  ${resp}  name=${SERVICE1}  description=${description}  serviceDuration=5   notification=${bool[1]}   notificationType=${notifytype[2]}   totalAmount=0.0  status=${status[0]}  bType=${btype}  isPrePayment=${bool[0]}  serviceType=virtualService   virtualServiceType=${vstype}


    
    ${resp}=  Get Service
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
   
    Set Suite Variable   ${p2_s1}   ${resp.json()[0]['id']}
    Set Suite Variable   ${P2SERVICE1}   ${resp.json()[0]['name']}
    Set Suite Variable   ${p2_s2}   ${resp.json()[1]['id']}
    Set Suite Variable   ${P2SERVICE2}   ${resp.json()[1]['name']}
   


    ${resp}=    Get Locations
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${p1_l1}   ${resp.json()[0]['id']}
    ${DAY}=  db.get_date_by_timezone  ${tz}
    # ${sTime1}=  db.get_time_by_timezone   ${tz}
    ${sTime1}=  db.get_time_by_timezone  ${tz}
    ${eTime1}=  add_timezone_time  ${tz}  0  25  
    ${p1queue1}=    FakerLibrary.word
    ${capacity}=  FakerLibrary.Numerify  %%
    ${list}=  Create List  1  2  3  4  5  6  7
    ${resp}=  Create Queue  ${p1queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime1}  ${eTime1}  1  ${capacity}  ${p1_l1}  ${p2_s1}  ${p2_s2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${P1queueId}  ${resp.json()}
    
    # ${resp}=    Enable Search Data
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  GetCustomer  phoneNo-eq=${CUSERNAME0}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${pcid2}  ${resp.json()[0]['id']}
    ${virtualService}=  Create Dictionary   ${CallingModes[1]}=${WHATSAPP_id2}
    ${desc}=   FakerLibrary.word
    Set Suite Variable  ${desc}
    ${resp}=  Provider Add To WL With Virtual Service  ${pcid2}  ${p2_s1}  ${P1queueId}  ${DAY}  ${desc}  ${bool[1]}  ${waitlistMode[2]}  ${virtualService}   0
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${wid9}  ${wid[0]}
    ${resp}=  Get Waitlist By Id  ${wid9} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  date=${DAY}  waitlistStatus=${wl_status[0]}  partySize=1  waitlistedBy=${waitlistedby[1]}   personsAhead=0  onlineRequest=${bool[0]}   waitlistMode=${waitlistMode[2]}   
    Should Be Equal As Strings  ${resp.json()['service']['name']}                 ${P2SERVICE1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}                   ${p2_s1}
    Should Be Equal As Strings  ${resp.json()['consumer']['id']}                  ${pcid2}
    Should Be Equal As Strings  ${resp.json()['waitlistingFor'][0]['id']}         0

    ${resp}=  Create Waitlist Meeting Request   ${wid9}   ${CallingModes[0]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Waitlist Meeting Request    ${wid9}    ${CallingModes[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Create Waitlist Meeting Request   ${wid9}   ${CallingModes[1]}   ${waitlistedby[1]}  ${waitlistedby[0]}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"

    ${resp}=  Get Waitlist Meeting Request    ${wid9}    ${CallingModes[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  "${resp.json()}"   "${VIRTUAL_CALLING_MODES_INVALID}"
    
 
    ${resp}=  ProviderLogout
    Should Be Equal As Strings  ${resp.status_code}  200

     ${resp}=    ProviderConsumer Login with token   ${CUSERNAME0}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Waitlist Meeting Details   ${wid9}    ${CallingModes[0]}     ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200


JD-TC-GetWaitlistMeetingDetails-UH2

    [Documentation]  COnsumer try to get details without login

    ${resp}=   Get Waitlist Meeting Details   ${wid9}    ${CallingModes[0]}   ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings  "${resp.json()}"   "${SESSION_EXPIRED}"
