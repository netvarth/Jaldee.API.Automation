*** Settings ***

Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        Comm Templates
Library           Collections
Library           String
Library           json
Library           FakerLibrary
Library           /ebs/TDD/Imageupload.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py 
Variables         /ebs/TDD/varfiles/hl_providers.py

*** Test Cases ***

JD-TC-CreateTemplateSettings-1

    [Documentation]  create a template without trigger point(send comm) for signup, SMS, SPConsumer, then add that using template settings.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME299}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id}  ${resp.json()['id']}

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}    ${comm_chanl} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${resp}=  Create Template Settings   ${temp_id1}  ${VariableContext[0]}  ${sendcomm_id1}  ${CommTarget[0]}    ${CommChannel[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Template By Id   ${temp_id1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings  ${resp.json()['accountId']}                   ${account_id} 
    Should Be Equal As Strings  ${resp.json()['templateName']}                ${temp_name}
    Should Be Equal As Strings  ${resp.json()['context']}                     ${VariableContext[0]} 
    Should Be Equal As Strings  ${resp.json()['commChannel']}                 ${comm_chanl} 
    Should Be Equal As Strings  ${resp.json()['templateFormat']}              ${templateFormat[0]}
    Should Be Equal As Strings  ${resp.json()['content']['intro']}            ${content_msg}
    Should Be Equal As Strings  ${resp.json()['commTarget']}                  ${comm_target} 
    Should Be Equal As Strings  ${resp.json()['status']}                      ${VarStatus[0]} 

JD-TC-CreateTemplateSettings-UH1

    [Documentation]  create a template with trigger point(send comm) for signup, SMS, SPConsumer, then add that using template settings also.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME300}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    ${sendcomm_list}=  Create List   ${sendcomm_id1}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}   ${comm_chanl}  sendComm=${sendcomm_list}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${TEMPLATE_SETTINGS_EXISTS}=  format String   ${TEMPLATE_SETTINGS_EXISTS}   ${CommChannel[0]} 

    ${resp}=  Create Template Settings   ${temp_id1}  ${VariableContext[0]}  ${sendcomm_id1}  ${CommTarget[0]}    ${CommChannel[0]}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_EXISTS}

JD-TC-CreateTemplateSettings-UH2

    [Documentation]   create a template settings without template id.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME298}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${resp}=  Create Template Settings   ${EMPTY}  ${VariableContext[0]}  ${sendcomm_id1}  ${CommTarget[0]}    ${CommChannel[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_TEMPLATE_SHOULD_BE_NOT_NULL}

JD-TC-CreateTemplateSettings-UH3

    [Documentation]   create a template settings without context.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME298}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}    ${comm_chanl} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${resp}=  Create Template Settings   ${temp_id1}  ${NULL}  ${sendcomm_id1}  ${CommTarget[0]}    ${CommChannel[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_CONTEXT_SHOULD_BE_NOT_NULL}

JD-TC-CreateTemplateSettings-UH4

    [Documentation]   create a template settings without comm target.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME298}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}    ${comm_chanl} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${resp}=  Create Template Settings   ${temp_id1}  ${VariableContext[0]}  ${sendcomm_id1}  ${NULL}    ${CommChannel[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_TARGET_SHOULD_BE_NOT_NULL}

JD-TC-CreateTemplateSettings-UH5

    [Documentation]   create a template settings without send comm id.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME298}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}    ${comm_chanl} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${resp}=  Create Template Settings   ${temp_id1}  ${VariableContext[0]}  ${EMPTY}  ${CommTarget[0]}    ${CommChannel[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_COMM_POINT_SHOULD_BE_NOT_NULL}

JD-TC-CreateTemplateSettings-UH6

    [Documentation]   create a template settings without comm channel.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME298}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${temp_name}=    FakerLibrary.word
    ${content_msg}=      FakerLibrary.sentence
    ${content}=    Create Dictionary  intro=${content_msg}
    ${comm_chanl}=   Create List   ${CommChannel[0]}  
    ${comm_target}=  Create List   ${CommTarget[0]}  
    
    ${resp}=  Create Template   ${temp_name}  ${content}  ${templateFormat[0]}  ${VariableContext[0]}  ${comm_target}    ${comm_chanl} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${temp_id1}  ${resp.json()}

    ${resp}=  Get Send Comm List
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable   ${sendcomm_id1}   ${resp.json()[0]['id']}

    ${resp}=  Create Template Settings   ${temp_id1}  ${VariableContext[0]}  ${sendcomm_id1}  ${CommTarget[0]}    ${NULL}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings  ${resp.json()}   ${TEMPLATE_SETTINGS_CHANNEL_SHOULD_BE_NOT_NULL}