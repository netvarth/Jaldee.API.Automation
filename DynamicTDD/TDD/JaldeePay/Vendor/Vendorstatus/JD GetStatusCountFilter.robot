*** Settings ***

Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Finance Manager
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           /ebs/TDD/db.py
Library           /ebs/TDD/excelfuncs.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py 


*** Test Cases ***


JD-TC-Get StatusCount Filter-1

    [Documentation]  Get VendorStatus With CountFilter with name.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME107}  ${PASSWORD}
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
    ${resp}=  CreateVendorStatus  ${name}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${encId}   ${resp.json()}


    ${resp}=   Get VendorStatus With CountFilter   name-eq=${name}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   1





JD-TC-Get StatusCount Filter-2

    [Documentation]   Get VendorStatus With CountFilter with createdDate

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorStatus With CountFilter   createdDate-ge=${CUR_DAY}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   2


JD-TC-Get StatusCount Filter-3

    [Documentation]   Get VendorStatus With CountFilter with status

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorStatus With CountFilter   status-eq=${toggle[0]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   1


JD-TC-Get StatusCount Filter-4

    [Documentation]   Get VendorStatus With CountFilter with encId

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorStatus With CountFilter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   1
    # Should Be Equal As Strings  ${resp.json()['name']}          ${name}


JD-TC-Get StatusCount Filter-5

    [Documentation]   Get VendorStatus With CountFilter with all fileds

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=   Get VendorStatus With CountFilter   encId-eq=${encId}   status-eq=${toggle[0]}  createdDate-ge=${CUR_DAY}  name-eq=${name}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   1


JD-TC-Get StatusCount Filter-6

    [Documentation]   Get VendorStatus With CountFilter with status

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=  Get VendorStatus With CountFilter   status-eq=${toggle[1]}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   0


JD-TC-Get StatusCount Filter-UH1

    [Documentation]  Get VendorStatus With CountFilter without login

    ${resp}=   Get VendorStatus With CountFilter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}

JD-TC-Get StatusCount Filter-UH2

    [Documentation]  Get VendorStatus With CountFilter Using Consumer Login

    ${resp}=  ConsumerLogin  ${CUSERNAME1}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get VendorStatus With CountFilter   encId-eq=${encId}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  401
    Should Be Equal As Strings   ${resp.json()}   ${LOGIN_NO_ACCESS_FOR_URL}


JD-TC-Get StatusCount Filter-UH3

    [Documentation]   Get VendorStatus With CountFilter where encId as wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
     ${fake}=    Random Int  min=1000000   max=9999999   
    ${resp}=   Get VendorStatus With CountFilter   encId-eq=${fake}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   0

JD-TC-Get StatusCount Filter-UH4

    [Documentation]    Get VendorStatus With CountFilter where created date is wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
     ${fake}=    Random Int  min=1000000   max=9999999   
    ${resp}=   Get VendorStatus With CountFilter   createdDate-ge=${DAY2}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   0

JD-TC-Get StatusCount Filter-UH5

    [Documentation]   Get VendorStatus With CountFilter where name  is wrong.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME107}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
    ${name}=   FakerLibrary.word
    ${resp}=  Get VendorStatus With CountFilter   name-eq=${name}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings   ${resp.json()}   0




