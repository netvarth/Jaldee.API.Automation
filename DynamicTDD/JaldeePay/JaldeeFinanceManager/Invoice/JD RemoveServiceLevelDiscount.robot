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
Variables         /ebs/TDD/varfiles/hl_providers.py

*** Variables ***

@{service_names}

${service_duration}     30

${self}         0


*** Test Cases ***

JD-TC-Remove Service Level Discount-1

    [Documentation]  Remove Service Level Discount.(non taxable)


    ${PUSERPH0}=  Evaluate  ${PUSERNAME}+3381833
    Set Suite Variable   ${PUSERPH0}

    ${firstname}  ${lastname}  ${PhoneNumber}  ${PUSERPH0}=  Provider Signup  PhoneNumber=${PUSERPH0}
    


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${result}=  Run Keyword If  ${resp.json()['enableAppt']}==${bool[0]}   Enable Disable Appointment   ${toggle[0]}
    Log   ${result.json()}
    Should Be Equal As Strings  ${result.status_code}  200

    ${resp}=   Get Account Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['appointment']}   ${bool[1]}
    

    ${accId}=  get_acc_id  ${PUSERPH0}
    Set Suite Variable  ${accId}




    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

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

    ${resp}=  Get Bill Settings 
    Log   ${resp.json}
    IF  ${resp.status_code}!=200
        Log   Status code is not 200: ${resp.status_code}
        ${resp}=  Enable Disable bill  ${bool[1]}
        Log   ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
    ELSE IF  ${resp.json()['enablepos']}==${bool[0]}
        ${resp}=  Enable Disable bill  ${bool[1]}
        Log   ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePresence']}==${bool[0]}
        ${resp}=  Set jaldeeIntegration Settings    ${bool[1]}  ${EMPTY}  ${EMPTY}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

    ${resp}=   Get jaldeeIntegration Settings
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}

    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


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

    
    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid}    ${resp}  

    ${resp}=   Get Location ById  ${lid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}
    
    ${name}=   FakerLibrary.word



    ${name1}=   FakerLibrary.word
    Set Suite Variable   ${name1}
    ${resp}=  Create Category   ${name1}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id2}   ${resp.json()}



    ${resp1}=  AddCustomer  ${CUSERNAME11}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable  ${pcid18}   ${resp1.json()}


    ${providerConsumerIdList}=  Create List  ${pcid18}
    Set Suite Variable  ${providerConsumerIdList}  

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${invoiceId}=   FakerLibrary.word


     ${SERVICE1}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${servicecharge}=  Convert To Number  ${servicecharge}  1
    ${srv_duration}=   Random Int   min=10   max=20
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid1}  ${resp.json()} 

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    #     ${serviceprice}=   Random Int  min=1000  max=1500
    # ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${serviceList}=  Create Dictionary  serviceId=${sid1}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Suite Variable   ${servicenetRate}
    
    
    ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${lid}    serviceList=${serviceList}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid}   ${resp.json()['uidList'][0]} 

    ${discount1}=     FakerLibrary.word
    ${desc}=   FakerLibrary.word
    ${discountprice1}=     Random Int   min=50   max=100
    ${discountprice}=  Convert To Number  ${discountprice1}  1
    Set Suite Variable   ${discountprice}
    ${resp}=   Create Discount  ${discount1}   ${desc}    ${discountprice}   ${calctype[1]}  ${disctype[0]}
    Log  ${resp.json()}
    Set Suite Variable   ${discountId}   ${resp.json()}   
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Discounts 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word
    ${discountValue1}=     Random Int   min=50   max=100
    ${discountValue1}=  Convert To Number  ${discountValue1}  1

    ${resp}=  Apply Service Level Discount   ${invoice_uid}   ${discountId}    ${discountValue1}   ${privateNote}  ${displayNote}   ${sid1}
    Log  ${resp.json()} 
    Should Be Equal As Strings  ${resp.status_code}  200
    ${netRate}=  Evaluate  ${servicenetRate} - ${discountprice}
    Set Test Variable   ${netRate}

    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['id']}   ${discountId}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['discountValue']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['privateNote']}   ${privateNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['displayNote']}   ${displayNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discountTotal']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['totalPrice']}   ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['netRate']}   ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netRate']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['temporaryTotalAmount']}     ${netRate}


    ${resp}=  Remove Service Level Discount   ${invoice_uid}   ${discountId}    ${discountValue1}   ${privateNote}  ${displayNote}   ${sid1}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200



    ${resp}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['serviceList'][0]['discounts']}  []
    Should Be Equal As Strings  ${resp.json()['netTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['amountDue']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['nonTaxableTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['temporaryTotalAmount']}     ${servicenetRate}


JD-TC-Remove Service Level Discount-2

    [Documentation]   Account is taxable-then try to apply and remove service level discount in before(means before tax enabled) created invoice.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word


    ${gstper}=  Random Element  ${gstpercentage}
    ${GST_num}  ${pan_num}=   Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstper}  ${GST_num}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Enable Tax
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Get Tax Percentage
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200  
    Set Suite Variable  ${tax_per}  ${resp.json()['taxPercentage']}

    # ${referenceNo}=   Random Int  min=5  max=200
    # ${referenceNo}=  Convert To String  ${referenceNo}

    # ${description}=   FakerLibrary.word
    # # Set Suite Variable  ${address}
    # ${invoiceLabel}=   FakerLibrary.word
    # ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    # ${invoiceId}=   FakerLibrary.word


    #  ${SERVICE1}=    generate_unique_service_name  ${service_names}
    # Set Suite Variable  ${SERVICE1}
    # ${desc}=   FakerLibrary.sentence
    # ${servicecharge}=   Random Int  min=100  max=500
    # ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}   
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable  ${sid2}  ${resp.json()} 

    # ${quantity}=   Random Int  min=5  max=10
    # ${quantity}=  Convert To Number  ${quantity}  1
    #     ${serviceprice}=   Random Int  min=1000  max=1500
    # ${serviceprice}=  Convert To Number  ${serviceprice}  1
    # ${serviceList}=  Create Dictionary  serviceId=${sid2}   quantity=${quantity}  price=${serviceprice}
    # ${serviceList}=    Create List    ${serviceList}
    # ${servicenetRate}=  Evaluate  ${quantity} * ${serviceprice}
    # ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    # Set Suite Variable   ${servicenetRate}
    
    
    # ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}   ${invoiceLabel}   ${address}   ${vendor_uid1}   ${invoiceId}    ${providerConsumerIdList}    serviceList=${serviceList}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${invoice_uid1}   ${resp.json()['uidList'][0]} 


    ${resp}=   Apply Service Level Discount   ${invoice_uid}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${netRate}=  Evaluate  ${servicenetRate} - ${discountprice}
    Set Test Variable   ${netRate}

    
        # ${netTaxAmount}=  Evaluate  ${netRate}*(${tax_per}/100)
        # ${netTaxAmount}=  Convert To Number  ${netTaxAmount}   2
        # ${total_amt_with_tax}=  Evaluate  ${netRate}+${netTaxAmount}
        # ${total_amt_with_tax}=  Convert To Number  ${total_amt_with_tax}   2

    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Not Contain   ${resp1.json()}    taxSettings
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['id']}   ${discountId}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['discountValue']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['privateNote']}   ${privateNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['displayNote']}   ${displayNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discountTotal']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['totalPrice']}   ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['netRate']}   ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netRate']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['temporaryTotalAmount']}     ${netRate}

    ${resp}=   Remove Service Level Discount   ${invoice_uid}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid1}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['serviceList'][0]['discounts']}  []
    Should Be Equal As Strings  ${resp.json()['netTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['amountDue']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['nonTaxableTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['temporaryTotalAmount']}     ${servicenetRate}

JD-TC-Remove Service Level Discount-3

    [Documentation]   Account is taxable,Service is non taxable-Create new invoice and check the remove service level discount.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word


    ${gstper}=  Random Element  ${gstpercentage}
    ${GST_num}  ${pan_num}=   Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstper}  ${GST_num}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Enable Tax
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Get Tax Percentage
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200  
    Set Suite Variable  ${tax_per}  ${resp.json()['taxPercentage']}

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${invoiceId}=   FakerLibrary.word


     ${SERVICE1}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${servicecharge}=  Convert To Number  ${servicecharge}  1
    ${srv_duration}=   Random Int   min=10   max=20
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid2}  ${resp.json()} 

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    #     ${serviceprice}=   Random Int  min=1000  max=1500
    # ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${serviceList}=  Create Dictionary  serviceId=${sid2}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}
    
    
    ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}    ${lid}   serviceList=${serviceList}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid1}   ${resp.json()['uidList'][0]} 


    ${resp}=   Apply Service Level Discount   ${invoice_uid1}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${netRate}=  Evaluate  ${servicenetRate} - ${discountprice}
    Set Test Variable   ${netRate}

    
        # ${netTaxAmount}=  Evaluate  ${netRate}*(${tax_per}/100)
        # ${netTaxAmount}=  Convert To Number  ${netTaxAmount}   2
        # ${total_amt_with_tax}=  Evaluate  ${netRate}+${netTaxAmount}
        # ${total_amt_with_tax}=  Convert To Number  ${total_amt_with_tax}   2

    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['id']}   ${discountId}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['discountValue']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['privateNote']}   ${privateNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['displayNote']}   ${displayNote}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discountTotal']}   ${discountprice}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['totalPrice']}   ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['netRate']}   ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['netRate']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}     ${netRate}
    Should Be Equal As Strings  ${resp1.json()['temporaryTotalAmount']}     ${netRate}

    ${resp}=   Remove Service Level Discount   ${invoice_uid1}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid2}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['serviceList'][0]['discounts']}  []
    Should Be Equal As Strings  ${resp.json()['netTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp.json()['amountTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['amountDue']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['nonTaxableTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp.json()['temporaryTotalAmount']}     ${servicenetRate}


JD-TC-Remove Service Level Discount-4

    [Documentation]   Account is taxable,Service is  taxable-Create new invoice -then apply and remove service level discount in that invoice.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word


    ${gstper}=  Random Element  ${gstpercentage}
    ${GST_num}  ${pan_num}=   Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstper}  ${GST_num}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Enable Tax
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${resp}=  Get Tax Percentage
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200  
    Set Suite Variable  ${tax_per}  ${resp.json()['taxPercentage']}

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${invoiceId}=   FakerLibrary.word


     ${SERVICE2}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE2}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${servicecharge}=  Convert To Number  ${servicecharge}  1
    ${srv_duration}=   Random Int   min=10   max=20    
    ${resp}=  Create Service  ${SERVICE2}  ${desc}   ${srv_duration}  ${bool[0]}  ${service_duration}  ${bool[0]}     
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid3}  ${resp.json()} 

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    #     ${serviceprice}=   Random Int  min=1000  max=1500
    # ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${serviceList}=  Create Dictionary  serviceId=${sid3}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}
    
    
    ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}    ${invoiceId}    ${providerConsumerIdList}   ${lid}   serviceList=${serviceList}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid2}   ${resp.json()['uidList'][0]} 


    ${resp}=   Apply Service Level Discount   ${invoice_uid2}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid3}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${netRate}=  Evaluate  ${servicenetRate} - ${discountprice}
    Set Test Variable   ${netRate}

    
        ${netTaxAmount}=  Evaluate  ${netRate}*(${tax_per}/100)
        ${netTaxAmount}=  Convert To Number  ${netTaxAmount}   2
        ${total_amt_with_tax}=  Evaluate  ${netRate}+${netTaxAmount}
        ${total_amt_with_tax}=  Convert To Number  ${total_amt_with_tax}   2
        ${netTotal}=  Evaluate  ${total_amt_with_tax}+${servicenetRate}
        ${netTotal}=  Convert To Number  ${netTotal}   2

    ${resp1}=  Get Invoice By Id  ${invoice_uid2}
    Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['id']}   ${discountId}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['discountValue']}   ${discountprice}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['privateNote']}   ${privateNote}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts'][0]['displayNote']}   ${displayNote}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discountTotal']}   ${discountprice}
    # Should Be Equal As Strings  ${resp1.json()['netTotal']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['netRate']}     ${total_amt_with_tax}
    # Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${total_amt_with_tax}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp1.json()['taxableTotal']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['temporaryTotalAmount']}     ${rate}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['totalPrice']}   ${servicenetRate}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['netRate']}   ${netRate}



    # Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}     ${netRate}
    # Should Be Equal As Strings  ${resp1.json()['temporaryTotalAmount']}     ${netRate}

    ${resp}=   Remove Service Level Discount   ${invoice_uid2}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid3}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200

    
        ${netTaxAmount1}=  Evaluate  ${servicenetRate}*(${tax_per}/100)
        ${netTaxAmount1}=  Convert To Number  ${netTaxAmount1}   2
        ${total_amt_with_tax1}=  Evaluate  ${servicenetRate}+${netTaxAmount1}
        ${total_amt_with_tax1}=  Convert To Number  ${total_amt_with_tax1}   2
        ${netTotal1}=  Evaluate  ${total_amt_with_tax1}+${servicenetRate}
        ${netTotal1}=  Convert To Number  ${netTotal1}   2

    ${resp}=  Get Invoice By Id  ${invoice_uid2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['serviceList'][0]['discounts']}  []
    # Should Be Equal As Strings  ${resp.json()['netTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp.json()['netRate']}     ${total_amt_with_tax1}
    # Should Be Equal As Strings  ${resp.json()['amountDue']}     ${total_amt_with_tax1}
    # Should Be Equal As Strings  ${resp.json()['taxableTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp.json()['taxableTotal']}     ${total_amt_with_tax1}









JD-TC-Remove Service Level Discount-UH1

    [Documentation]   Remove Service Level Discount that already removed..


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word
        ${discountValue1}=     Random Int   min=50   max=100
    ${discountValue1}=  Convert To Number  ${discountValue1}  1

    ${resp}=   Remove Service Level Discount   ${invoice_uid1}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid2}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}   ${INCORRECT_DISCOUNT_ID}

JD-TC-Remove Service Level Discount-UH2

    [Documentation]  Remove Service Level Discount where Invoice uid is wrong.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word
    ${invoice}=   FakerLibrary.word

    ${resp}=   Remove Service Level Discount   ${invoice}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid3}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}   ${INVALID_FM_INVOICE_ID}

JD-TC-Remove Service Level Discount-UH3

    [Documentation]  Remove Service Level Discount where discount id is wrong.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word
    ${discount}=   FakerLibrary.RandomNumber

    ${resp}=   Remove Service Level Discount   ${invoice_uid1}   ${discount}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid2}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}   ${INCORRECT_DISCOUNT_ID}

JD-TC-Remove Service Level Discount-UH4

    [Documentation]  Remove Service Level Discount where serviceid is wrong.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word
    ${item}=  FakerLibrary.RandomNumber


    ${resp}=   Remove Service Level Discount   ${invoice_uid2}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${item}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}   ${SERVICE_NOT}

JD-TC-Remove Service Level Discount-UH5

    [Documentation]  Remove Service Level Discount using another provider login.


    ${resp}=   Encrypted Provider Login  ${PUSERNAME134}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word

    ${resp}=   Remove Service Level Discount   ${invoice_uid2}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid3}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    # Should Be Equal As Strings  ${resp.json()}   ${INVALID_FM_INVOICE_ID}
    Should Be Equal As Strings  ${resp.json()}   ${CAP_JALDEE_FINANCE_DISABLED}



JD-TC-Remove Service Level Discount-UH7

    [Documentation]  update bill status and try to Remove Service Level Discount .


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp1}=  Get Invoice By Id  ${invoice_uid2}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${billStatusNote}=   FakerLibrary.word
    ${resp}=  Update bill status   ${invoice_uid2}    ${billStatus[0]}   ${billStatusNote}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Update bill status   ${invoice_uid2}    ${billStatus[1]}   ${billStatusNote} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${INVOICE_STATUS}=  format String   ${INVOICE_STATUS}   ${billStatus[1]}
    # ${INVOICE_SETTLED}=  format String   ${INVOICE_SETTLED}   ${billStatus[1]}

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word

    ${resp}=   Remove Service Level Discount   ${invoice_uid2}   ${discountId}    ${discountprice}   ${privateNote}  ${displayNote}  ${sid3}
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}   ${INVOICE_STATUS}


*** Comments ***
JD-TC-Remove Service Level Discount-6

    [Documentation]   Service auto invoice generation is on,then took walkin appointment  and check whethrer invoice is created there .




    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

    ${pid}=  get_acc_id  ${PUSERPH0}
    ${cid}=  get_id  ${CUSERNAME32}

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableAppt']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['enableToday']}   ${bool[1]}  

    ${lid}=  Create Sample Location  
    Set Suite Variable  ${lid}
    ${resp}=   Get Location ById  ${lid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}
    # clear_appt_schedule   ${PUSERPH0}

    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    ${desc}=   FakerLibrary.sentence
    ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${servicecharge}=  Convert To Number  ${servicecharge}  1 
    ${srv_duration}=   Random Int   min=10   max=20
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[1]}  ${servicecharge}  ${bool[0]}  minPrePaymentAmount=${min_pre}   automaticInvoiceGeneration=${bool[1]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    Set Test Variable  ${s_id}  ${resp.json()}
    
    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${DAY2}=  db.add_timezone_date  ${tz}  10        
    ${list}=  Create List  1  2  3  4  5  6  7
    ${sTime1}=  add_timezone_time  ${tz}  0  15  
    ${delta}=  FakerLibrary.Random Int  min=10  max=60
    ${eTime1}=  add_two   ${sTime1}  ${delta}

    # ${resp}=  Auto Invoice Generation For Service   ${s_id}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${s_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}
    Set Test Variable   ${tot_amt}   ${resp.json()['totalAmount']}


    ${schedule_name}=  FakerLibrary.bs
    ${parallel}=  FakerLibrary.Random Int  min=1  max=10
    ${maxval}=  Convert To Integer   ${delta/2}
    ${duration}=  FakerLibrary.Random Int  min=1  max=${maxval}
    ${bool1}=  Random Element  ${bool}
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}    ${parallel}  ${lid}  ${duration}  ${bool1}  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

     ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456987
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo}
    ${email}=    FakerLibrary.Email
    Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${pid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    # ${resp}=    Consumer Logout
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo}     ${pid}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${pid}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${resp}=    Get All Schedule Slots By Date Location and Service  ${pid}  ${DAY1}  ${lid}  ${s_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${no_of_slots}=  Get Length  ${resp.json()[0]['availableSlots']}
    @{slots}=  Create List
    FOR   ${i}  IN RANGE   0   ${no_of_slots}
        IF  ${resp.json()[0]['availableSlots'][${i}]['noOfAvailbleSlots']} > 0   
            Set Test Variable   ${a${i}}  ${resp.json()[0]['availableSlots'][${i}]['time']}
            Append To List   ${slots}  ${resp.json()[0]['availableSlots'][${i}]['time']}
        END
    END
    ${num_slots}=  Get Length  ${slots}
    ${j}=  Random Int  max=${num_slots-1}
    Set Suite Variable   ${slot1}   ${slots[${j}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}



    ${cnote}=   FakerLibrary.word
    ${resp}=   Customer Take Appointment  ${pid}   ${s_id}  ${sch_id}  ${DAY1}  ${cnote}  ${apptfor}  location=${{str('${lid}')}}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get From Dictionary  ${resp.json()}  ${firstName}
    Set Suite Variable   ${apptid1}

    ${resp}=   Get consumer Appointment By Id   ${pid}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 

    ${resp}=  Get Appointment Slots By Date Schedule  ${sch_id}  ${DAY1}   ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  scheduleName=${schedule_name}  scheduleId=${sch_id}
    Set Test Variable   ${slot1}   ${resp.json()['availableSlots'][0]['time']}

    # ${resp}=  AddCustomer  ${CUSERNAME2}   firstName=${fname1}   lastName=${lname1}
    # Log   ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Test Variable  ${cid}  ${resp.json()}

    # ${resp}=  GetCustomer  phoneNo-eq=${CUSERNAME2}
    # Log   ${resp.json()}
    # Should Be Equal As Strings      ${resp.status_code}  200
    # Set Test Variable   ${jaldeeid1}    ${resp.json()[0]['jaldeeId']}
    
    
    # ${apptfor1}=  Create Dictionary  id=${cid}   apptTime=${slot1}
    # ${apptfor}=   Create List  ${apptfor1}
    
    # ${cnote}=   FakerLibrary.word
    # ${resp}=  Take Appointment For Consumer  ${cid}  ${s_id}  ${sch_id}  ${DAY1}  ${cnote}  ${apptfor}  location=${lid}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
          
    # ${apptid}=  Get Dictionary Values  ${resp.json()}   sort_keys=False
    # Set Test Variable  ${apptid1}  ${apptid[1]}

    ${resp}=  Get Appointment EncodedID   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${encId}=  Set Variable   ${resp.json()}

    ${resp}=  Get Appointment By Id   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['uid']}                              ${apptid1}
    Should Be Equal As Strings  ${resp.json()['appointmentEncId']}                  ${encId}
    Should Be Equal As Strings  ${resp.json()['providerConsumer']['id']}            ${cid}
    Should Be Equal As Strings  ${resp.json()['providerConsumer']['phoneNo']}        ${CUSERNAME2}
    Should Be Equal As Strings  ${resp.json()['providerConsumer']['jaldeeId']}      ${jaldeeid1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}                      ${s_id}
    Should Be Equal As Strings  ${resp.json()['schedule']['id']}                      ${sch_id}
    Should Be Equal As Strings  ${resp.json()['apptStatus']}                          ${apptStatus[1]}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['firstName']}             ${fname1}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['lastName']}              ${lname1}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['apptTime']}              ${slot1}
    Should Be Equal As Strings  ${resp.json()['appmtDate']}                            ${DAY1}
    Should Be Equal As Strings  ${resp.json()['appmtTime']}                            ${slot1}
    Should Be Equal As Strings  ${resp.json()['location']['id']}                       ${lid}

    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()[0]['netTotal']}     ${tot_amt}
    Should Be Equal As Strings  ${resp1.json()[0]['netRate']}     ${tot_amt}
    Should Be Equal As Strings  ${resp1.json()[0]['amountDue']}     ${tot_amt}
    # Should Be Equal As Strings  ${resp1.json()[0]['amountTotal']}     ${tot_amt}

JD-TC-Remove Service Level Discount-7

    [Documentation]   Service auto invoice generation is off,then took one appointment from consumer side  and check  invoice is not created there .then add service level discount.


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

    ${pid}=  get_acc_id  ${PUSERPH0}
    ${cid}=  get_id  ${CUSERNAME32}

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word

    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid}    ${resp}  

    ${resp}=   Get Location ById  ${lid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

    # ${CUR_DAY}=  db.get_date_by_timezone  ${tz}
    # Set Suite Variable  ${CUR_DAY}
  
    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    ${desc}=   FakerLibrary.sentence
    ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${servicecharge}=  Convert To Number  ${servicecharge}  1 
    ${srv_duration}=   Random Int   min=10   max=20
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[1]}  ${servicecharge}  ${bool[0]}  minPrePaymentAmount=${min_pre}   automaticInvoiceGeneration=${bool[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    Set Test Variable  ${s_id}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${s_id}    ${toggle[1]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  422

    ${resp}=   Get Service By Id  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[0]}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1

    ${serviceList}=  Create Dictionary  serviceId=${s_id}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}


    # clear_appt_schedule   ${PUSERPH0}

    ${resp}=  Get Appointment Schedules
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableAppt']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['enableToday']}   ${bool[1]}

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${DAY2}=  db.add_timezone_date  ${tz}  10      
    ${list}=  Create List  1  2  3  4  5  6  7
    ${sTime1}=  db.add_timezone_time     ${tz}  0  15
    ${delta}=  FakerLibrary.Random Int  min=10  max=60
    ${eTime1}=  add_two   ${sTime1}  ${delta}
    ${schedule_name}=  FakerLibrary.bs
    ${parallel}=  FakerLibrary.Random Int  min=1  max=10
    ${maxval}=  Convert To Integer   ${delta/2}
    ${duration}=  FakerLibrary.Random Int  min=1  max=${maxval}
    ${bool1}=  Random Element  ${bool}
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime}  ${eTime1}  ${parallel}    ${parallel}  ${lid}  ${duration}  ${bool1}  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

    # ${resp}=  Consumer Login  ${CUSERNAME32}  ${PASSWORD}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # Set Test Variable  ${jdconID}   ${resp.json()['id']}

    ${resp}=    Send Otp For Login    ${CUSERNAME32}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME32}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME32}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${fname}   ${resp.json()['firstName']}
    Set Test Variable  ${lname}   ${resp.json()['lastName']}

    ${resp}=  Get Appointment Schedules Consumer  ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Appointment Schedule ById Consumer  ${sch_id}   ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Next Available Appointment Slots By ScheduleId  ${sch_id}   ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${no_of_slots}=  Get Length  ${resp.json()['availableSlots']}
    @{slots}=  Create List
    FOR   ${i}  IN RANGE   0   ${no_of_slots}
        IF  ${resp.json()['availableSlots'][${i}]['noOfAvailbleSlots']} > 0   
            Append To List   ${slots}  ${resp.json()['availableSlots'][${i}]['time']}
        END
    END
    ${num_slots}=  Get Length  ${slots}
    ${j}=  Random Int  max=${num_slots-1}
    Set Test Variable   ${slot1}   ${slots[${j}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}

    ${cnote}=   FakerLibrary.name
    ${resp}=   Take Appointment For Provider   ${pid}  ${s_id}  ${sch_id}  ${DAY1}  ${cnote}   ${apptfor}    location=${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get From Dictionary  ${resp.json()}  ${fname}
    Set Suite Variable   ${apptid1}

    ${resp}=   Get consumer Appointment By Id   ${pid}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    Verify Response    ${resp}     uid=${apptid1}   appmtDate=${DAY1}   appmtTime=${slot1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}   ${s_id}
    Should Be Equal As Strings  ${resp.json()['schedule']['id']}   ${sch_id}
    Should Be Equal As Strings  ${resp.json()['apptStatus']}  ${apptStatus[0]}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['firstName']}   ${fname}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['lastName']}   ${lname}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['apptTime']}   ${slot1}
    Should Be Equal As Strings  ${resp.json()['location']['id']}   ${lid}

    sleep  02s

    ${resp}=  Encrypted Provider Login    ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    sleep  02s
     ${NO_INVOICE_GENERATED}=  format String   ${NO_INVOICE_GENERATED}   ${apptid1}
    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  422
    Should Be Equal As Strings  ${resp1.json()}   ${NO_INVOICE_GENERATED}


    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${invoiceId}=   FakerLibrary.word

    
    
    ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}     ${invoiceId}    ${providerConsumerIdList}   ${lid}   serviceList=${serviceList}   ynwUuid=${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoice_uid1}   ${resp.json()['uidList'][0]} 

    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Not Contain    ${resp1.json()['serviceList'][0]}   discounts
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['discounts']}  []
    Should Be Equal As Strings  ${resp1.json()['netTotal']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['netRate']}     ${servicenetRate}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}     ${servicenetRate}
    # Should Be Equal As Strings  ${resp1.json()['taxableTotal']}     ${servicecharge}

JD-TC-Remove Service Level Discount-UH6

    [Documentation]   Service auto invoice generation is off by default,then took one appointment from consumer side  and check  invoice is not created there .


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

    ${pid}=  get_acc_id  ${PUSERPH0}
    ${cid}=  get_id  ${CUSERNAME32}

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word

    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid}    ${resp}  

    ${resp}=   Get Location ById  ${lid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

    # ${CUR_DAY}=  db.get_date_by_timezone  ${tz}
    # Set Suite Variable  ${CUR_DAY}
  
    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    ${desc}=   FakerLibrary.sentence
    ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${servicecharge}=  Convert To Number  ${servicecharge}  1 
    ${srv_duration}=   Random Int   min=10   max=20
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[1]}  ${servicecharge}  ${bool[0]}  minPrePaymentAmount=${min_pre}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    Set Test Variable  ${s_id}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${s_id}    ${toggle[1]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  422

    ${resp}=   Get Service By Id  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[0]}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1

    ${serviceList}=  Create Dictionary  serviceId=${s_id}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}


    # clear_appt_schedule   ${PUSERPH0}

    ${resp}=  Get Appointment Schedules
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableAppt']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['enableToday']}   ${bool[1]}

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${DAY2}=  db.add_timezone_date  ${tz}  10      
    ${list}=  Create List  1  2  3  4  5  6  7
    ${sTime1}=  db.add_timezone_time     ${tz}  0  15
    ${delta}=  FakerLibrary.Random Int  min=10  max=60
    ${eTime1}=  add_two   ${sTime1}  ${delta}
    ${schedule_name}=  FakerLibrary.bs
    ${parallel}=  FakerLibrary.Random Int  min=1  max=10
    ${maxval}=  Convert To Integer   ${delta/2}
    ${duration}=  FakerLibrary.Random Int  min=1  max=${maxval}
    ${bool1}=  Random Element  ${bool}
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}    ${parallel}  ${lid}  ${duration}  ${bool1}  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

    # ${resp}=  Consumer Login  ${CUSERNAME32}  ${PASSWORD}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # Set Test Variable  ${jdconID}   ${resp.json()['id']}

    ${resp}=    Send Otp For Login    ${CUSERNAME32}    ${account_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME32}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME32}    ${account_id}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${fname}   ${resp.json()['firstName']}
    Set Test Variable  ${lname}   ${resp.json()['lastName']}

    ${resp}=  Get Appointment Schedules Consumer  ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Appointment Schedule ById Consumer  ${sch_id}   ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Next Available Appointment Slots By ScheduleId  ${sch_id}   ${pid}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${no_of_slots}=  Get Length  ${resp.json()['availableSlots']}
    @{slots}=  Create List
    FOR   ${i}  IN RANGE   0   ${no_of_slots}
        IF  ${resp.json()['availableSlots'][${i}]['noOfAvailbleSlots']} > 0   
            Append To List   ${slots}  ${resp.json()['availableSlots'][${i}]['time']}
        END
    END
    ${num_slots}=  Get Length  ${slots}
    ${j}=  Random Int  max=${num_slots-1}
    Set Test Variable   ${slot1}   ${slots[${j}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}

    ${cnote}=   FakerLibrary.name
    ${resp}=   Take Appointment For Provider   ${pid}  ${s_id}  ${sch_id}  ${DAY1}  ${cnote}   ${apptfor}    location=${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get From Dictionary  ${resp.json()}  ${fname}
    Set Suite Variable   ${apptid1}

    ${resp}=   Get consumer Appointment By Id   ${pid}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    Verify Response    ${resp}     uid=${apptid1}   appmtDate=${DAY1}   appmtTime=${slot1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}   ${s_id}
    Should Be Equal As Strings  ${resp.json()['schedule']['id']}   ${sch_id}
    Should Be Equal As Strings  ${resp.json()['apptStatus']}  ${apptStatus[0]}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['firstName']}   ${fname}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['lastName']}   ${lname}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['apptTime']}   ${slot1}
    Should Be Equal As Strings  ${resp.json()['location']['id']}   ${lid}

    sleep  02s

    ${resp}=  Encrypted Provider Login    ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    sleep  02s
     ${NO_INVOICE_GENERATED}=  format String   ${NO_INVOICE_GENERATED}   ${apptid1}
    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  422
    Should Be Equal As Strings  ${resp1.json()}   ${NO_INVOICE_GENERATED}


JD-TC-Remove Service Level Discount-5

    [Documentation]   Service auto invoice generation is on,then took one appointment from consumer side  and check whethrer invoice is created there .then remove servicel level discount


    ${resp}=   Encrypted Provider Login  ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

    ${pid}=  get_acc_id  ${PUSERPH0}
    ${cid}=  get_id  ${CUSERNAME32}

    ${privateNote}=     FakerLibrary.word
    ${displayNote}=   FakerLibrary.word

    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid}    ${resp}  

    ${resp}=   Get Location ById  ${lid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

    # ${CUR_DAY}=  db.get_date_by_timezone  ${tz}
    # Set Suite Variable  ${CUR_DAY}
  
    ${SERVICE1}=    FakerLibrary.name
    ${desc}=   FakerLibrary.sentence
    ${min_pre}=   Random Int   min=1   max=50
    ${servicecharge}=   Random Int  min=100  max=500
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${servicecharge}=  Convert To Number  ${servicecharge}  1 
    ${srv_duration}=   Random Int   min=10   max=20
    
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[1]}  ${servicecharge}  ${bool[0]}  minPrePaymentAmount=${min_pre}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    Set Test Variable  ${s_id}  ${resp.json()}

    ${resp}=  Auto Invoice Generation For Service   ${s_id}    ${toggle[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}


    # clear_appt_schedule   ${PUSERPH0}

    ${resp}=  Get Appointment Schedules
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableAppt']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['enableToday']}   ${bool[1]}

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${DAY2}=  db.add_timezone_date  ${tz}  10      
    ${list}=  Create List  1  2  3  4  5  6  7
    ${sTime1}=  db.add_timezone_time     ${tz}  0  15
    ${delta}=  FakerLibrary.Random Int  min=10  max=60
    ${eTime1}=  add_two   ${sTime1}  ${delta}
    ${schedule_name}=  FakerLibrary.bs
    ${parallel}=  FakerLibrary.Random Int  min=1  max=10
    ${maxval}=  Convert To Integer   ${delta/2}
    ${duration}=  FakerLibrary.Random Int  min=1  max=${maxval}
    ${bool1}=  Random Element  ${bool}
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}    ${parallel}  ${lid}  ${duration}  ${bool1}  ${s_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

    # ${resp}=  Consumer Login  ${CUSERNAME32}  ${PASSWORD}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # Set Test Variable  ${jdconID}   ${resp.json()['id']}
    # Set Test Variable  ${fname}   ${resp.json()['firstName']}
    # Set Test Variable  ${lname}   ${resp.json()['lastName']}

    # ${resp}=  Get Appointment Schedules Consumer  ${pid}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=  Get Appointment Schedule ById Consumer  ${sch_id}   ${pid}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=  Get Next Available Appointment Slots By ScheduleId  ${sch_id}   ${pid}
    # Log   ${resp.json()}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # ${no_of_slots}=  Get Length  ${resp.json()['availableSlots']}
    # @{slots}=  Create List
    # FOR   ${i}  IN RANGE   0   ${no_of_slots}
    #     IF  ${resp.json()['availableSlots'][${i}]['noOfAvailbleSlots']} > 0   
    #         Append To List   ${slots}  ${resp.json()['availableSlots'][${i}]['time']}
    #     END
    # END
    # ${num_slots}=  Get Length  ${slots}
    # ${j}=  Random Int  max=${num_slots-3}
    # Set Test Variable   ${slot1}   ${slots[${j}]}

    # ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    # ${apptfor}=   Create List  ${apptfor1}

    # ${cnote}=   FakerLibrary.name
    # ${resp}=   Take Appointment For Provider   ${pid}  ${s_id}  ${sch_id}  ${DAY1}  ${cnote}   ${apptfor}    location=${lid}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456987
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo}
    ${email}=    FakerLibrary.Email
    Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${pid}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    # ${resp}=    Consumer Logout
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo}     ${pid}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${pid}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${resp}=    Get All Schedule Slots By Date Location and Service  ${pid}  ${DAY1}  ${lid}  ${s_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${no_of_slots}=  Get Length  ${resp.json()[0]['availableSlots']}
    @{slots}=  Create List
    FOR   ${i}  IN RANGE   0   ${no_of_slots}
        IF  ${resp.json()[0]['availableSlots'][${i}]['noOfAvailbleSlots']} > 0   
            Set Test Variable   ${a${i}}  ${resp.json()[0]['availableSlots'][${i}]['time']}
            Append To List   ${slots}  ${resp.json()[0]['availableSlots'][${i}]['time']}
        END
    END
    ${num_slots}=  Get Length  ${slots}
    ${j}=  Random Int  max=${num_slots-1}
    Set Suite Variable   ${slot1}   ${slots[${j}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}



    ${cnote}=   FakerLibrary.word
    ${resp}=   Customer Take Appointment  ${pid}   ${s_id}  ${sch_id}  ${DAY1}  ${cnote}  ${apptfor}  location=${{str('${lid}')}}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get From Dictionary  ${resp.json()}  ${fname}
    Set Suite Variable   ${apptid1}

    ${resp}=   Get consumer Appointment By Id   ${pid}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    # Verify Response    ${resp}     uid=${apptid1}   appmtDate=${DAY1}   appmtTime=${slot1}
    # Should Be Equal As Strings  ${resp.json()['service']['id']}   ${s_id}
    # Should Be Equal As Strings  ${resp.json()['schedule']['id']}   ${sch_id}
    # Should Be Equal As Strings  ${resp.json()['apptStatus']}  ${apptStatus[1]}
    # Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['firstName']}   ${fname}
    # Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['lastName']}   ${lname}
    # Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['apptTime']}   ${slot1}
    # Should Be Equal As Strings  ${resp.json()['location']['id']}   ${lid}

    sleep  02s

    ${resp}=  Encrypted Provider Login    ${PUSERPH0}  ${PASSWORD} 
    Log  ${resp.json()}         
    Should Be Equal As Strings            ${resp.status_code}    200

    sleep  02s
    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
