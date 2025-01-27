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
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py 

*** Variables ***

@{service_names}

${jpgfile}      /ebs/TDD/uploadimage.jpg
${pngfile}      /ebs/TDD/upload.png
${pdffile}      /ebs/TDD/sample.pdf
${jpgfile2}      /ebs/TDD/small.jpg
${gif}      /ebs/TDD/sample.gif
${xlsx}      /ebs/TDD/qnr.xlsx

${order}    0
${fileSize}  0.00458




*** Test Cases ***


JD-TC- Update default category by type-1

    [Documentation]   Create Category as Expense and  Update default category by type.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME97}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

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

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[0]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[1]}

    ${name}=   FakerLibrary.word
    ${resp}=  Create Category   ${name}  ${categoryType[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id1}   ${resp.json()}

    ${resp}=  Update default category by type   ${category_id1}  ${categoryType[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Default Category By Type   ${categoryType[1]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['id']}            ${category_id1}
    Should Be Equal As Strings  ${resp.json()['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[1]}
    Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}

    

# JD-TC- Update default category by type-2

#     [Documentation]  Create Category as Expense and  Update default category by type.

#     ${resp}=  Encrypted Provider Login    ${PUSERNAME97}  ${PASSWORD}
#     Log  ${resp.json()}         
#     Should Be Equal As Strings            ${resp.status_code}    200

#     ${name}=   FakerLibrary.word
#     ${resp}=  Create Category   ${name}  ${categoryType[1]} 
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200
#     Set Test Variable   ${category_id1}   ${resp.json()}

#     ${resp}=  Update default category by type   ${category_id1}  ${categoryType[1]} 
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200

#     ${resp}=  Get Default Category By Type  ${categoryType[1]}
#     Log  ${resp.json()}
#     Should Be Equal As Strings  ${resp.status_code}  200
#     Should Be Equal As Strings  ${resp.json()['id']}            ${category_id1}
#     Should Be Equal As Strings  ${resp.json()['name']}          ${name}
#     Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[1]}
#     Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
#     Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}


JD-TC- Update default category by type-2

    [Documentation]  Create Category as Payable and  Update default category by type.

      ${resp}=  Encrypted Provider Login    ${PUSERNAME97}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200
    
    ${name}=   FakerLibrary.word
    ${resp}=  Create Category   ${name}  ${categoryType[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${category_id1}   ${resp.json()}

    ${resp}=  Update default category by type   ${category_id1}   ${categoryType[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Default Category By Type   ${categoryType[2]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['id']}            ${category_id1}
    Should Be Equal As Strings  ${resp.json()['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[2]}
    Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}


JD-TC- Update default category by type-3

    [Documentation]  Create Category as Invoice and  Update default category by type.

    ${resp}=  Encrypted Provider Login    ${PUSERNAME97}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${name}=   FakerLibrary.word
    ${resp}=  Create Category   ${name}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${category_id1}   ${resp.json()}

    ${resp}=  Update default category by type   ${category_id1}    ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Default Category By Type   ${categoryType[3]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['id']}            ${category_id1}
    Should Be Equal As Strings  ${resp.json()['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[3]}
    Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}




  

JD-TC- Update default category by type-UH1

    [Documentation]   Update default category by type without login

    ${resp}=  Update default category by type   ${category_id1}  ${categoryType[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}

JD-TC- Update default category by type-UH2

    [Documentation]    Update default category by type Using Consumer Login

    ${resp}=  Encrypted Provider Login  ${PUSERNAME97}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200



    #............provider consumer creation..........

    ${PH_Number}=  FakerLibrary.Numerify  %#####
    ${PH_Number}=    Evaluate    f'{${PH_Number}:0>7d}'
    Log  ${PH_Number}
    Set Suite Variable  ${PCPHONENO}  555${PH_Number}

    ${fname}=  generate_firstname
    Set Suite Variable  ${fname}
    ${lastname}=  FakerLibrary.last_name
   
    ${resp}=  AddCustomer  ${PCPHONENO}    firstName=${fname}   lastName=${lastname}  countryCode=${countryCodes[1]} 
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Provider Logout
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Send Otp For Login    ${PCPHONENO}    ${account_id1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${PCPHONENO}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${PCPHONENO}    ${account_id1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200


   ${resp}=  Update default category by type   ${category_id1}  ${categoryType[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  401
    Should Be Equal As Strings   ${resp.json()}   ${LOGIN_NO_ACCESS_FOR_URL}



*** Comments ***   


JD-TC- Update default category by type-UH3

    [Documentation]  Create Category as Vendor then update it as Expense  .

      ${resp}=  Encrypted Provider Login    ${PUSERNAME105}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id1}  ${resp.json()['id']}

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[0]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[1]}
    
    ${name1}=   FakerLibrary.word
    ${resp}=  Create Category   ${name1}  ${categoryType[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id1}   ${resp.json()}

    ${resp}=  Get Default Category By Type   ${categoryType[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()['id']}            ${category_id1}
    # Should Be Equal As Strings  ${resp.json()['name']}          ${name1}
    # Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[0]}
    # Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
    # Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}

    ${name2}=   FakerLibrary.word
    ${resp}=  Update Category   ${category_id1}  ${name2}  ${categoryType[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id2}   ${resp.json()}

    ${resp}=  Get Default Category By Type   ${categoryType[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # ${len}=  Get Length  ${resp.json()}    
    # Should Be Equal As Strings  ${len}  3    

JD-TC- Update default category by type-UH4

    [Documentation]  Create multiple Category as Vendor and try to  Update with different category by type.

      ${resp}=  Encrypted Provider Login    ${PUSERNAME98}  ${PASSWORD}
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${account_id1}  ${resp.json()['id']}

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[0]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
    END

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[1]}
    
    ${name1}=   FakerLibrary.word
    ${resp}=  Create Category   ${name1}  ${categoryType[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${category_id1}   ${resp.json()}

    ${resp}=  Update default category by type   ${category_id1}  ${categoryType[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${name2}=   FakerLibrary.word
    ${resp}=  Create Category   ${name2}  ${categoryType[0]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${category_id2}   ${resp.json()}


    ${resp}=  Update default category by type   ${category_id2}  ${categoryType[2]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}     ${CANT_SET_PAYMENT}

