*** Settings ***
Suite Teardown    Delete All Sessions
Force Tags        Provider Login
Library           Collections
Library           String
Library           json
Library           /ebs/TDD/db.py
Library           FakerLibrary
Library           /ebs/TDD/CustomKeywords.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables       /ebs/TDD/varfiles/providers.py
Variables       /ebs/TDD/varfiles/consumerlist.py 

*** Variables ***
      
${withsym}      *#147erd
${onlyspl}      !@#$%^&
${alph_digits}  D3r52A

*** Test Cases ***

JD-TC-UNLINK_ONE_LOGIN-1

    [Documentation]    Unlink Login - link provider 2 and provider 3 after that unlink provider 2

    ${domresp}=  Get BusinessDomainsConf
    Log  ${domresp.json()}
    Should Be Equal As Strings  ${domresp.status_code}  200
    ${len}=  Get Length  ${domresp.json()}
    ${domain_list}=  Create List
    ${subdomain_list}=  Create List
    FOR  ${domindex}  IN RANGE  ${len}
        Set Test Variable  ${d}  ${domresp.json()[${domindex}]['domain']}    
        Append To List  ${domain_list}    ${d} 
        Set Test Variable  ${sd}  ${domresp.json()[${domindex}]['subDomains'][0]['subDomain']}
        Append To List  ${subdomain_list}    ${sd} 
    END
    Log  ${domain_list}
    Log  ${subdomain_list}
    Set Suite Variable  ${domain_list}
    Set Suite Variable  ${subdomain_list}

    # ........ Provider 1 ..........

    ${ph}=  Evaluate  ${PUSERNAME}+5666010
    Set Suite Variable  ${ph}
    ${firstname}=  generate_firstname
    ${lastname}=  FakerLibrary.last_name
    Set Suite Variable      ${firstname}
    Set Suite Variable      ${lastname}

    ${highest_package}=  get_highest_license_pkg

    ${resp}=  Account SignUp  ${firstname}  ${lastname}  ${None}  ${domain_list[0]}  ${subdomain_list[0]}  ${ph}   ${highest_package[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation  ${ph}  ${OtpPurpose['ProviderSignUp']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${loginId}=     Random Int  min=1111  max=9999
    Set Suite Variable      ${loginId}
    
    ${resp}=  Account Set Credential  ${ph}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${loginId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${resp}=  Provider Login  ${loginId}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable          ${username}    ${resp.json()['userName']}

    #..... User Creation ......

    ${resp}=  Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${acc_id}   ${resp.json()['id']}
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}

    ${user1}=  Create Sample User 
    Set suite Variable                    ${user1}
    
    ${resp}=  Get User By Id              ${user1}
    Log   ${resp.json()}
    Should Be Equal As Strings            ${resp.status_code}  200
    Set Suite Variable  ${user_n1}    ${resp.json()['mobileNo']}


    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ........ Provider 2 ..........

    ${ph2}=  Evaluate  ${PUSERNAME}+5660022
    Set Suite Variable  ${ph2}
    ${firstname2}=  generate_firstname
    ${lastname2}=  FakerLibrary.last_name
    Set Suite Variable      ${firstname2}
    Set Suite Variable      ${lastname2}

    ${resp}=  Account SignUp  ${firstname2}  ${lastname2}  ${None}  ${domain_list[0]}  ${subdomain_list[0]}  ${ph2}   1
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation  ${ph2}  ${OtpPurpose['ProviderSignUp']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${loginId2}=     Random Int  min=1111  max=9999
    Set Suite Variable      ${loginId2}
    
    ${resp}=  Account Set Credential  ${ph2}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${loginId2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${resp}=  Provider Login  ${loginId2}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable          ${username2}    ${resp.json()['userName']}

    ${resp}=  Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${acc_id2}   ${resp.json()['id']}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ........ Provider 3 ..........

    ${ph3}=  Evaluate  ${PUSERNAME}+5667542
    Set Suite Variable  ${ph3}
    ${firstname3}=  generate_firstname
    ${lastname3}=  FakerLibrary.last_name
    Set Suite Variable      ${firstname3}
    Set Suite Variable      ${lastname3}

    ${resp}=  Account SignUp  ${firstname3}  ${lastname3}  ${None}  ${domain_list[0]}  ${subdomain_list[0]}  ${ph3}   1
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation  ${ph3}  ${OtpPurpose['ProviderSignUp']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${loginId3}=     Random Int  min=1111  max=9999
    Set Suite Variable      ${loginId3}
    
    ${resp}=  Account Set Credential  ${ph3}  ${PASSWORD}  ${OtpPurpose['ProviderSignUp']}  ${loginId3}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    
    ${resp}=  Provider Login  ${loginId3}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable          ${username3}    ${resp.json()['userName']}

    ${resp}=  Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${acc_id3}   ${resp.json()['id']}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Provider Login  ${loginId}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Connect with other login  ${loginId2}  password=${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation      ${ph2}  ${OtpPurpose['LinkLogin']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${key2} =   db.Verify Accnt   ${ph2}    ${OtpPurpose['LinkLogin']}
    Set Suite Variable   ${key2}

    ${resp}=    Connect with other login  ${loginId2}   otp=${key2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['userName']}     ${username2}
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['accountId']}    ${acc_id2}


    ${resp}=    Connect with other login  ${loginId3}  password=${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation      ${ph3}  ${OtpPurpose['LinkLogin']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${key2} =   db.Verify Accnt   ${ph3}    ${OtpPurpose['LinkLogin']}
    Set Suite Variable   ${key2}

    ${resp}=    Connect with other login  ${loginId3}   otp=${key2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['userName']}     ${username2}
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['accountId']}    ${acc_id2}
    Should Be Equal As Strings    ${resp.json()['${loginId3}']['userName']}     ${username3}
    Should Be Equal As Strings    ${resp.json()['${loginId3}']['accountId']}    ${acc_id3}

    ${resp}=    Unlink one login  ${loginId2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['${loginId3}']['userName']}     ${username3}
    Should Be Equal As Strings    ${resp.json()['${loginId3}']['accountId']}    ${acc_id3}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-2

    [Documentation]    Unlink Login - unliked provider geting linked list 

    ${resp}=  Provider Login  ${loginId2}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${dict}=    Create Dictionary
    Set Suite Variable      ${dict}

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}        ${dict}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-3

    [Documentation]    Unlink Login - Provider 3 login and unlink provider 1

    ${resp}=  Provider Login  ${loginId3}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['${loginId}']['userName']}     ${username}
    Should Be Equal As Strings    ${resp.json()['${loginId}']['accountId']}    ${acc_id}

    ${resp}=    Unlink one login  ${loginId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}        ${dict}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-4

    [Documentation]    Unlink Login - Provider 1 login get linked lists where everyone have unlinked

    ${resp}=  Provider Login  ${loginId}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}        ${dict}
    
    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-UH1

    [Documentation]    Unlink Login - who is already unlinked

    ${resp}=  Provider Login  ${loginId3}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Unlink one login  ${loginId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}    ${ALREADY_UNLINKED}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-UH2

    [Documentation]    Unlink Login - without login 

    ${resp}=    Unlink one login  ${loginId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   419
    Should Be Equal As Strings    ${resp.json()}    ${SESSION_EXPIRED}

JD-TC-UNLINK_ONE_LOGIN-UH3

    [Documentation]    Unlink Login - self unlinking

    ${resp}=  Provider Login  ${loginId}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Unlink one login  ${loginId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}    ${ALREADY_UNLINKED}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-UH4

    [Documentation]    Unlink Login - unlinking with invalid login id

    ${resp}=  Provider Login  ${loginId}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${inv}=  Random Int  min=1111  max=999999

    ${resp}=    Unlink one login  ${inv}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}    ${UNLINKING_LOGINID_NOT_EXIST}

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-UNLINK_ONE_LOGIN-5

    [Documentation]    Unlink Login - login existing login and link one and after unlink and check   

    ${resp}=    Provider Logout
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Provider Login  ${PUSERNAME110}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Connect with other login  ${loginId2}  password=${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    202

    ${resp}=    Account Activation      ${ph2}  ${OtpPurpose['LinkLogin']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${key2} =   db.Verify Accnt   ${ph2}    ${OtpPurpose['LinkLogin']}
    Set Suite Variable   ${key2}

    ${resp}=    Connect with other login  ${loginId2}   otp=${key2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['userName']}     ${username2}
    Should Be Equal As Strings    ${resp.json()['${loginId2}']['accountId']}    ${acc_id2}

    ${resp}=    Unlink one login  ${loginId2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${dict}=    Create Dictionary

    ${resp}=    List all links of a loginId
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()}        ${dict}