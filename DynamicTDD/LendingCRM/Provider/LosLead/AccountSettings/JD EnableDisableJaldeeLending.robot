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
Resource           /ebs/TDD/ProviderConsumerKeywords.robot
Resource           /ebs/TDD/ProviderPartnerKeywords.robot
Variables          /ebs/TDD/varfiles/providers.py
Variables          /ebs/TDD/varfiles/consumerlist.py 
Variables          /ebs/TDD/varfiles/hl_providers.py


*** Test Cases ***

JD-TC-EnableDisableJaldeeLending-1

    [Documentation]  Enable Disable Jaldee Lending

    ${resp}=   Encrypted Provider Login  ${PUSERNAME101}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['jaldeeLending']}         ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['losLoanApplication']}    ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['losLead']}               ${bool[0]}
    Should Be Equal As Strings  ${resp.json()['losLoan']}               ${bool[0]}

    IF  '${resp.json()['jaldeeLending']}'=='${bool[0]}'

        ${resp}=    Enable Disable Jaldee Lending  ${toggle[0]}
        Log  ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}   200

    END

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['jaldeeLending']}  ${bool[1]}

JD-TC-EnableDisableJaldeeLending-UH1

    [Documentation]  Enable Disable Jaldee Lending - which is already enabled

    ${resp}=   Encrypted Provider Login  ${PUSERNAME101}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${ALREDY_ENABLED}=  format String   ${ALREDY_ENABLED}   Jaldee Lending AI

    ${resp}=    Enable Disable Jaldee Lending  ${toggle[0]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}        ${ALREDY_ENABLED}

JD-TC-EnableDisableJaldeeLending-2

    [Documentation]  Enable Disable Jaldee Lending - disabled which is enabled

    ${resp}=   Encrypted Provider Login  ${PUSERNAME101}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Enable Disable Jaldee Lending  ${toggle[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

JD-TC-EnableDisableJaldeeLending-UH2

    [Documentation]  Enable Disable Jaldee Lending - disable already disabled

    ${resp}=   Encrypted Provider Login  ${PUSERNAME101}  ${PASSWORD} 
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${ALREDY_DISABLED}=  format String   ${ALREDY_DISABLED}   Jaldee Lending AI

    ${resp}=    Enable Disable Jaldee Lending  ${toggle[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}        ${ALREDY_DISABLED}

JD-TC-EnableDisableJaldeeLending-UH3

    [Documentation]  Enable Disable Jaldee Lending - without Login

    ${resp}=    Enable Disable Jaldee Lending  ${toggle[1]}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   419
    Should Be Equal As Strings    ${resp.json()}        ${SESSION_EXPIRED}