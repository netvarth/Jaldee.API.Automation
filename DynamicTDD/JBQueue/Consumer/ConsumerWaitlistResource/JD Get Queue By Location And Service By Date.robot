*** Settings ***
# Suite Teardown    Run Keywords  Delete All Sessions  resetsystem_time
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags      Queue
Library         Collections
Library         String
Library         json
Library           FakerLibrary
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/consumermail.py
  
*** Variables ***
${service_duration}   5   


*** Test Cases ***
JD-TC-Get Queue By Location and Service By Date-1

	[Documentation]  Get Queue By Location and Service By Date

    ${f_name}=  FakerLibrary.first_name
    ${l_name}=  FakerLibrary.last_name
    ${resp}=    get_mutilocation_domains
    Log   ${resp}
    Set Test Variable   ${sector}        ${resp[0]['domain']}
    Set Test Variable   ${sub_sector}    ${resp[0]['subdomains'][0]}
    ${PUSERNAME_P}=  Evaluate  ${PUSERNAME}+91234
    Append To File  ${EXECDIR}/data/TDD_Logs/numbers.txt  ${PUSERNAME_P}${\n}   
    ${pkg_id}=   get_highest_license_pkg
    ${resp}=   Account SignUp  ${f_name}  ${l_name}  ${None}   ${sector}   ${sub_sector}  ${PUSERNAME_P}  ${pkg_id[0]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    202
    ${resp}=  Account Activation  ${PUSERNAME_P}  0
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}=  Account Set Credential  ${PUSERNAME_P}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${PUSERNAME_P}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable   ${PUSERNAME_P}
    
    ${resp}=  Encrypted Provider Login  ${PUSERNAME_P}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${decrypted_data}=  db.decrypt_data  ${resp.content}
    Log  ${decrypted_data}
    Set Test Variable  ${pid}  ${decrypted_data['id']}
    
    ${bs}=  FakerLibrary.bs
    ${companySuffix}=  FakerLibrary.companySuffix
    ${parking}   Random Element   ${parkingType}
    ${24hours}    Random Element    ['True','False']
    ${desc}=   FakerLibrary.sentence
    ${url}=   FakerLibrary.url
    ${name3}=  FakerLibrary.word
    ${emails1}=  Emails  ${name3}  Email  ${PUSERNAME_P}${P_Email}.${test_mail}  ${views}
    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    ${tz}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    Set Test Variable  ${tz}
    ${DAY1}=  db.get_date_by_timezone  ${tz}

    ${b_loc}=  Create Dictionary  place=${city}   longitude=${longi}   lattitude=${latti}    googleMapUrl=${url}   pinCode=${postcode}  address=${address}
    ${emails}=  Create List  ${emails1}
    ${resp}=  Update Business Profile with kwargs   businessName=${bs}   shortName=${bs}   businessDesc=Description baseLocation=${b_loc}   emails=${emails}  
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    Set Test Variable  ${email_id}  ${P_Email}${PUSERNAME_P}.${test_mail}

    ${resp}=  Update Email   ${p_id}   ${f_name}   ${l_name}   ${email_id}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${loc_list}=  Create List
    ${resp}=    Get Locations
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${loc_length}=  Get Length  ${resp.json()}
    FOR   ${i}  IN RANGE   ${loc_length}
        Append To List   ${loc_list}  ${resp.json()[${i}]['place']}
    END


    ${DAY}=  db.get_date_by_timezone  ${tz}   
    Set Suite Variable  ${DAY} 
    ${tomorrow}=  db.add_timezone_date  ${tz}  1     
    Set Suite Variable  ${tomorrow} 
    ${list}=  Create List  1  2  3  4  5  6  7
    Set Suite Variable  ${list}

    FOR  ${i}  IN RANGE   5
        ${city}=   FakerLibrary.state
        ${keywordstatus} 	${value} = 	Run Keyword And Ignore Error   List Should Not Contain Value  ${loc_list}  ${city}
        Log Many  ${keywordstatus} 	${value}
        Continue For Loop If  '${keywordstatus}' == 'FAIL'
        Run Keyword If  '${keywordstatus}' == 'PASS'  Append To List   ${loc_list}  ${city}
        Exit For Loop IF   '${keywordstatus}' == 'PASS'
    END
    

    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    ${tz1}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    Set Suite Variable  ${tz1}
    ${sTime}=  db.get_time_by_timezone  ${tz1}
    ${eTime}=  add_timezone_time  ${tz1}  0  30
    ${parking}    Random Element     ${parkingType} 
    ${24hours}    Random Element    ['True','False']
    ${url}=   FakerLibrary.url
    ${resp}=  Create Location  ${city}  ${longi}  ${latti}  ${url}  ${postcode}  ${address}  ${parking}  ${24hours}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${stime}  ${etime}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    ${loc_result} = 	Convert To Integer 	 ${resp.json()}
    Set Suite Variable  ${p1_l1}   ${loc_result}

    FOR  ${i}  IN RANGE   5
        ${city}=   FakerLibrary.state
        ${keywordstatus} 	${value} = 	Run Keyword And Ignore Error   List Should Not Contain Value  ${loc_list}  ${city}
        Log Many  ${keywordstatus} 	${value}
        Continue For Loop If  '${keywordstatus}' == 'FAIL'
        Run Keyword If  '${keywordstatus}' == 'PASS'  Append To List   ${loc_list}  ${city}
        Exit For Loop IF   '${keywordstatus}' == 'PASS'
    END
    
    ${latti}  ${longi}  ${postcode}  ${city}  ${district}  ${state}  ${address}=  get_loc_details
    ${tz2}=   db.get_Timezone_by_lat_long   ${latti}  ${longi}
    Set Suite Variable  ${tz2}
    ${sTime1}=  add_timezone_time  ${tz2}  0  30
    ${eTime1}=  add_timezone_time  ${tz2}  1  00
    ${parking}    Random Element     ${parkingType} 
    ${24hours}    Random Element    ['True','False']
    ${url}=   FakerLibrary.url
    ${resp}=  Create Location  ${city}  ${longi}  ${latti}  ${url}  ${postcode}  ${address}  ${parking}  ${24hours}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${stime}  ${etime}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    ${loc_result} = 	Convert To Integer 	 ${resp.json()}
    Set Suite Variable  ${p1_l2}   ${loc_result}

    ${P1SERVICE1}=    FakerLibrary.word
    Set Suite Variable  ${P1SERVICE1}
    ${desc}=   FakerLibrary.sentence
    # ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${resp}=  Create Service  ${P1SERVICE1}  ${desc}   ${service_duration}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}   ${EMPTY}  ${servicecharge}  ${bool[0]}  ${bool[0]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_s1}  ${resp.json()} 

    ${P1SERVICE2}=    FakerLibrary.word
    Set Suite Variable  ${P1SERVICE2}
    ${desc}=   FakerLibrary.sentence
    # ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${resp}=  Create Service  ${P1SERVICE2}  ${desc}   ${service_duration}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}   ${EMPTY}  ${servicecharge}  ${bool[0]}  ${bool[0]}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_s2}  ${resp.json()} 

    ${P1SERVICE3}=    FakerLibrary.word
    Set Suite Variable   ${P1SERVICE3}
    ${desc}=   FakerLibrary.sentence
    # ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${resp}=  Create Service  ${P1SERVICE3}  ${desc}   ${service_duration}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}   ${EMPTY}  ${servicecharge}  ${bool[0]}  ${bool[0]}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_s3}  ${resp.json()}

    ${sTime1}=  add_timezone_time  ${tz1}  1  00
    ${eTime1}=  add_timezone_time  ${tz1}  1  30
    ${p1queue1}=    FakerLibrary.word
    Set Suite Variable   ${p1queue1}
    ${capacity}=  FakerLibrary.Numerify  %%%
    ${parallel}=  FakerLibrary.Numerify  %
    ${resp}=  Create Queue  ${p1queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}  ${capacity}  ${p1_l1}  ${p1_s1} 
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_q1}  ${resp.json()}

    ${sTime2}=  add_timezone_time  ${tz2}  1  30
    ${eTime2}=  add_timezone_time  ${tz2}  2  00
    ${p1queue2}=    FakerLibrary.word
    Set Suite Variable   ${p1queue2}
    ${capacity}=  FakerLibrary.Numerify  %%%
    ${parallel}=  FakerLibrary.Numerify  %
    ${resp}=  Create Queue  ${p1queue2}  ${recurringtype[1]}  ${list}  ${tomorrow}  ${EMPTY}  ${EMPTY}  ${sTime2}  ${eTime2}  ${parallel}  ${capacity}  ${p1_l2}   ${p1_s2} 
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_q2}  ${resp.json()} 

    ${sTime2}=  add_timezone_time  ${tz2}  2  00
    ${eTime2}=  add_timezone_time  ${tz2}  2  30
    ${p1queue3}=    FakerLibrary.word
    Set Suite Variable   ${p1queue3}
    ${capacity}=  FakerLibrary.Numerify  %%%
    ${parallel}=  FakerLibrary.Numerify  %
    ${resp}=  Create Queue  ${p1queue3}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime2}  ${eTime2}  ${parallel}  ${capacity}  ${p1_l2}  ${p1_s3} 
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_q3}  ${resp.json()}

    ${resp}=  Disable Queue  ${p1_q3}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${accId}=  get_acc_id  ${PUSERNAME_P}
    Set Suite Variable  ${accId}  ${accId}

    ${fname}=  FakerLibrary.first_name
    ${lname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${CUSERNAME2}   firstName=${fname}   lastName=${lname}  countryCode=${countryCodes[1]}  
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${cid}  ${resp.json()}

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${CUSERNAME2}    ${accId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Verify Otp For Login   ${CUSERNAME2}   ${OtpPurpose['Authentication']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME2}    ${accId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable   ${fname}   ${resp.json()['firstName']}

    ${resp}=  Get Queue By Location and service By Date  ${p1_l1}  ${p1_s1}  ${DAY}  ${accId}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['id']}  ${p1_q1} 
    Should Be Equal As Strings  ${resp.json()[0]['name']}  ${p1queue1}

JD-TC-Get Queue By Location and Service By Date-2
	[Documentation]  Get Queue By Location and Service By Date 
    ${resp}=  Consumer Login  ${CUSERNAME9}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Queue By Location and service By Date  ${p1_l2}  ${p1_s2}  ${tomorrow}  ${accId}
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200  
    Should Be Equal As Strings  ${resp.json()[0]['id']}  ${p1_q2} 
    Should Be Equal As Strings  ${resp.json()[0]['name']}  ${p1queue2}

JD-TC-Get Queue By Location and Service By Date-UH1
	[Documentation]  Get Queue By Location and Service By Date
    ${resp}=  Consumer Login  ${CUSERNAME9}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Queue By Location and service By Date  ${p1_l1}  ${p1_s2}  ${DAY}  ${accId}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()}  []

JD-TC-Get Queue By Location and Service By Date-UH2
	[Documentation]  Get Queue By Location and Service By Date url using another providers accunt id
    ${resp}=  Consumer Login  ${CUSERNAME9}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${accId1}=  get_acc_id  ${PUSERNAME111}

    ${resp}=  Get Queue By Location and service By Date  ${p1_l2}  ${p1_s2}  ${DAY}  ${accId1}
    # Should Be Equal As Strings  ${resp.status_code}  401
    # Should Be Equal As Strings  "${resp.json()}"  "${NO_PERMISSION}" 
    Should Be Equal As Strings  ${resp.status_code}   404
    Should Be Equal As Strings  "${resp.json()}"   "${LOCATION_NOT_FOUND}"  

JD-TC-Get Queue By Location and Service By Date-3
	[Documentation]  Get Queue By Location and Service By Date url without login

    ${resp}=  Get Queue By Location and service By Date  ${p1_l2}  ${p1_s2}  ${DAY}  ${accId}
    Should Be Equal As Strings  ${resp.status_code}  200

JD-TC-Get Queue By Location and Service By Date-UH3
	[Documentation]  try to get Disbled queue
    ${resp}=  Consumer Login  ${CUSERNAME9}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Queue By Location and service By Date  ${p1_l2}  ${p1_s3}  ${DAY}  ${accId}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()}  []         
