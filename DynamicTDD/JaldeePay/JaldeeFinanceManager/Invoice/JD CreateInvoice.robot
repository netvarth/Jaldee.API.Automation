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

${self}         0

${SERVICE6}     SAMPLE1
${SERVICE7}     SAMPLE2
${SERVICE8}     SAMPLE3

${order}    0
${service_duration}     30
${service_duration1}     10
${DisplayName1}   item1_DisplayName
${Booking}      Booking

*** Test Cases ***

JD-TC-CreateInvoice-1

    [Documentation]  Create a invoice with valid details.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}

    Set Suite Variable  ${pid}  ${decrypted_data['id']}
    Set Suite Variable    ${pdrname}    ${decrypted_data['userName']}
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


    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid1}    ${resp}  

    ${resp}=   Get Location ById  ${lid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}


    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${lid}   ${resp.json()[1]['id']}

    ${name}=   FakerLibrary.word
    Set Suite Variable   ${name}

    ${resp}=  CreateVendorCategory  ${name}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id}   ${resp.json()}

    ${resp}=  Get by encId  ${category_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    ${name}=   FakerLibrary.word
    ${resp}=  Create Category   ${name}  ${categoryType[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id1}   ${resp.json()}

    ${name1}=   FakerLibrary.word
    Set Suite Variable   ${name1}
    ${resp}=  Create Category   ${name1}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id2}   ${resp.json()}

    ${resp}=  Get Category By Id   ${category_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200



    ${resp1}=  AddCustomer  ${CUSERNAME11}
    Log  ${resp1.json()}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable   ${pcid18}   ${resp1.json()}

    ${providerConsumerIdList}=  Create List  ${pcid18}
    Set Suite Variable  ${providerConsumerIdList}   


    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    # ${invoiceDate}=   Get Current Date    result_format=%Y/%m/%d
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoiceId}   ${resp.json()}

    ${item1}=     FakerLibrary.word
    ${itemCode1}=     FakerLibrary.word
    ${price1}=     Random Int   min=400   max=500
    ${price}=  Convert To Number  ${price1}  1
    Set Suite Variable  ${price} 
    ${resp}=  Create Sample Item   ${DisplayName1}   ${item1}  ${itemCode1}  ${price}  ${bool[1]} 
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${itemId}  ${resp.json()}

    ${resp}=   Get Item By Id  ${itemId}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${promotionalPrice}   ${resp.json()['promotionalPrice']}


    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    ${itemList}=  Create Dictionary  itemId=${itemId}   quantity=${quantity}   price=${promotionalPrice}
    # ${itemList}=    Create List    ${itemList}

    ${resp}=  Create Finance Status   ${New_status[0]}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${status_id1}   ${resp.json()}

    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${serviceprice}=   Random Int  min=10  max=15
    ${serviceprice}=  Convert To Number  ${serviceprice}  1
    
  
    ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${service_duration}  ${bool[0]}  ${servicecharge}  ${bool[1]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid1}  ${resp.json()}

    ${serviceList}=  Create Dictionary  serviceId=${sid1}   quantity=${quantity}  price=${serviceprice}
    ${serviceList}=    Create List    ${serviceList}


    ${itemName}=    FakerLibrary.word
    Set Suite Variable  ${itemName}
    ${price}=   Random Int  min=10  max=15
    ${price}=  Convert To Number  ${price}  1
    ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price}
    ${adhocItemList}=    Create List    ${adhocItemList}

    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}     ${invoiceId}    ${providerConsumerIdList}  ${lid}   ${itemList}  invoiceStatus=${status_id1}    serviceList=${serviceList}   adhocItemList=${adhocItemList}   locationId=${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_id}   ${resp.json()['idList'][0]}
    Set Suite Variable   ${invoice_uid}   ${resp.json()['uidList'][0]}    

    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid1}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price}


    FOR   ${a}  IN RANGE   15
       
        ${resp}=  Flush Analytics Data to DB
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        sleep  01s
        Exit For Loop If    ${resp.content}=="FREE"
    
    END
    #Finance Invoice Total
    ${resp}=  Get Finance Analytics  frequency=${dateCategory[0]}   accId=${pid}   locationId=${lid}     metricId=161    
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
JD-TC-CreateInvoice-2

    [Documentation]  Create multiple invoice using multiple provider consumers.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${lid}   ${resp.json()[1]['id']}

    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}

    ${resp1}=  AddCustomer  ${CUSERNAME10}
    Log  ${resp1.json()}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable   ${pcid10}   ${resp1.json()}

    ${resp1}=  AddCustomer  ${CUSERNAME9}
    Log  ${resp1.json()}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable   ${pcid9}   ${resp1.json()}

    ${providerConsumerIdList}=  Create List  ${pcid10}  ${pcid9}
    Set Test Variable  ${providerConsumerIdList}   

    ${itemName}=    FakerLibrary.word
    Set Suite Variable  ${itemName}
    ${price}=   Random Int  min=10  max=15
    ${price}=  Convert To Number  ${price}  1

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price}
    ${adhocItemList}=    Create List    ${adhocItemList}
    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${lid}  adhocItemList=${adhocItemList}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid1}   ${resp.json()['uidList'][0]}  
    Set Suite Variable  ${invoice_uid2}   ${resp.json()['uidList'][1]}  

    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['providerConsumerId']}  ${pcid10}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price}

    ${resp1}=  Get Invoice By Id  ${invoice_uid2}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['providerConsumerId']}  ${pcid9}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price}

JD-TC-CreateInvoice-3

    [Documentation]  Create  invoice using service list,item list and status.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    ${amount}=   Random Int  min=500  max=2000
    ${amount}=     roundoff    ${amount}   1
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}

    ${resp1}=  AddCustomer  ${CUSERNAME12}
    Log  ${resp1.json()}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable   ${pcid12}   ${resp1.json()}

    ${providerConsumerIdList}=  Create List  ${pcid12} 
    Set Test Variable  ${providerConsumerIdList}   


    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1

    ${itemList}=  Create Dictionary  itemId=${itemId}   quantity=${quantity}  price=${promotionalPrice}
    ${netRate}=  Evaluate  ${promotionalPrice}*${quantity}
     ${netRate}=  Convert To Number  ${netRate}  4

    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}    ${invoiceId}    ${providerConsumerIdList}   ${lid}    ${itemList}  invoiceStatus=${status_id1}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid3}   ${resp.json()['uidList'][0]}  



    ${resp1}=  Get Invoice By Id  ${invoice_uid3}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['providerConsumerId']}  ${pcid12}
    Should Be Equal As Strings  ${resp1.json()['itemList'][0]['itemId']}  ${itemId}
    Should Be Equal As Strings  ${resp1.json()['itemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['itemList'][0]['price']}  ${promotionalPrice}
    Should Be Equal As Strings  ${resp1.json()['itemList'][0]['netRate']}  ${netRate}

JD-TC-CreateInvoice-4

    [Documentation]  Service price is zero(so auto invoice generation flag is disbled)-then create invoice .

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=   Get License UsageInfo 
    # Log  ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Get upgradable license 
    #    Log   ${resp.json()}
    #    Should Be Equal As Strings    ${resp.status_code}   200
    #    ${len}=  Get Length  ${resp.json()}
    #    ${len}=  Evaluate  ${len}-1
    #    Set Test Variable  ${licId1}  ${resp.json()[${len}]['pkgId']}
    #    ${resp}=  Change License Package  ${licId1}
    #    Should Be Equal As Strings    ${resp.status_code}   200
     

    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    ${desc}=   FakerLibrary.sentence
    ${min_pre}=   Random Int   min=1   max=50
    # ${servicecharge}=    0
    ${min_pre}=  Convert To Number  ${min_pre}  1
    ${srv_duration}=   Random Int   min=10   max=20
    # minPrePaymentAmount=${min_pre}
    ${resp}=  Create Service  ${SERVICE1}  ${desc}  ${srv_duration}  ${bool[0]}  0  ${bool[0]}   automaticInvoiceGeneration=${bool[0]}
    # ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}   ${status[0]}  ${btype}   ${bool[1]}  ${notifytype[2]}   ${min_pre}  ${order}  ${bool[1]}  ${bool[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}   200
    Set Test Variable  ${s_id}  ${resp.json()}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1

    ${serviceList}=  Create Dictionary  serviceId=${s_id}   quantity=${quantity}  price=${order}
    ${serviceList}=    Create List    ${serviceList}

    # ${resp}=  Auto Invoice Generation For Service   ${s_id}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    ${amount}=   Random Int  min=500  max=2000
    ${amount}=     roundoff    ${amount}   1
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}

    ${resp1}=  AddCustomer  ${CUSERNAME13}
    Log  ${resp1.json()}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Set Suite Variable   ${pcid12}   ${resp1.json()}

    ${providerConsumerIdList}=  Create List  ${pcid12} 
    Set Test Variable  ${providerConsumerIdList}   


    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${lid}    serviceList=${serviceList}    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid3}   ${resp.json()['uidList'][0]}  


JD-TC-CreateInvoice-UH1

    [Documentation]  Create a invoice with EMPTY invoiceCategoryId.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}

    ${itemName}=    FakerLibrary.word
    Set Suite Variable  ${itemName}
    ${price}=   Random Int  min=10  max=15
    ${price}=  Convert To Number  ${price}  1

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price}
    ${adhocItemList}=    Create List    ${adhocItemList}
    
    ${resp}=  Create Invoice   ${EMPTY}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${lid}  adhocItemList=${adhocItemList}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}  ${INVALID_INVOICE_CATEGORY}

JD-TC-CreateInvoice-UH2

    [Documentation]  Create a invoice with EMPTY invoiceDate.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}

    ${itemName}=    FakerLibrary.word
    Set Suite Variable  ${itemName}
    ${price}=   Random Int  min=10  max=15
    ${price}=  Convert To Number  ${price}  1

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price}
    ${adhocItemList}=    Create List    ${adhocItemList}
    
    ${resp}=  Create Invoice   ${category_id2}    ${EMPTY}      ${invoiceId}    ${providerConsumerIdList}  ${lid}  adhocItemList=${adhocItemList}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}  ${INVOICE_DATE_CANNOT_EMPTY}

JD-TC-CreateInvoice-UH3

    [Documentation]  Create a invoice with EMPTY service list,itemlist and adhoc list.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME40}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}

    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${invoiceId}   ${resp.json()}
    
    ${resp}=  Create Invoice   ${category_id2}   ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}  ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  422
    Should Be Equal As Strings  ${resp.json()}  ${LINE_ITEMS_CANNOT_EMPTY}
    
JD-TC-CreateInvoice-5

    [Documentation]  Provider take one walking checkin and create invoice using that waitlist id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}

    Set Suite Variable  ${pid}  ${decrypted_data['id']}
    Set Suite Variable    ${pdrname}    ${decrypted_data['userName']}
    Set Suite Variable    ${pdrfname}    ${decrypted_data['firstName']}
    Set Suite Variable    ${pdrlname}    ${decrypted_data['lastName']}
    
    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${account_id1}  ${resp.json()['id']}

    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    IF  ${resp.json()['filterByDept']}==${bool[0]}
        ${resp}=  Enable Disable Department  ${toggle[0]}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
    END
    
    #sleep  2s
    ${resp}=  Get Departments
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${dep_id}  ${resp.json()['departments'][0]['departmentId']}

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

    ${resp}=  AddCustomer  ${CUSERNAME14}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${cid}  ${resp.json()}

    ${resp}=  GetCustomer  phoneNo-eq=${CUSERNAME14}
    Log   ${resp.json()}
    Should Be Equal As Strings      ${resp.status_code}  200



     
    ${resp}=  Create Sample Location  
    Set Suite Variable    ${loc_id1}    ${resp}  

    ${resp}=   Get Location ById  ${loc_id1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

    ${CUR_DAY}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${CUR_DAY}

    ${resp}=   Create Sample Service  ${SERVICE1}   department=${dep_id}
    Set Suite Variable    ${ser_id1}    ${resp}  
    # ${resp}=   Create Sample Service  ${SERVICE2}   department=${dep_id}
    # Set Suite Variable    ${ser_id2}    ${resp}  
    # ${resp}=   Create Sample Service  ${SERVICE3}   department=${dep_id}
    # Set Suite Variable    ${ser_id3}    ${resp}  
    ${q_name}=    FakerLibrary.name
    Set Suite Variable    ${q_name}
    ${list}=  Create List   1  2  3  4  5  6  7
    Set Suite Variable    ${list}
    ${strt_time}=   db.add_timezone_time     ${tz}  1  00
    Set Suite Variable    ${strt_time}
    ${end_time}=    db.add_timezone_time     ${tz}  3  00 
    Set Suite Variable    ${end_time}   
    ${parallel}=   Random Int  min=1   max=1
    Set Suite Variable   ${parallel}
    ${capacity}=  Random Int   min=10   max=20
    Set Suite Variable   ${capacity}
    ${resp}=  Create Queue    ${q_name}  ${recurringtype[1]}  ${list}  ${CUR_DAY}  ${EMPTY}  ${EMPTY}  ${strt_time}  ${end_time}  ${parallel}   ${capacity}    ${loc_id1}  ${ser_id1}  
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${que_id1}   ${resp.json()}
    ${desc}=   FakerLibrary.word
    Set Suite Variable  ${desc}
    ${resp}=  Add To Waitlist  ${cid}  ${ser_id1}  ${que_id1}  ${CUR_DAY}  ${desc}  ${bool[1]}  ${cid} 
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
      
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${wid}  ${wid[0]}
    ${resp}=  Get Waitlist By Id  ${wid} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # Set Suite Variable   ${fullAmount}  ${resp.json()['fullAmt']}         

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    ${invoiceId}=   FakerLibrary.word
    
    ${quantity}=   Random Int  min=500  max=1000
    ${quantity}=  Convert To Number  ${quantity}  1
    ${servicecharge}=   Random Int  min=5  max=10


    ${serviceList}=  Create Dictionary  serviceId=${ser_id1}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}

    ${name1}=   FakerLibrary.word
    ${resp}=  Create Category   ${name1}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${category_id}   ${resp.json()}
    
    ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${loc_id1}   serviceList=${serviceList}        ynwUuid=${wid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid3}   ${resp.json()['uidList'][0]}  



    ${resp1}=  Get Invoice By Id  ${invoice_uid3}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}



JD-TC-CreateInvoice-6

    [Documentation]  Provider take one online checkin and create invoice using that waitlist id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Test Variable  ${account_id1}  ${resp.json()['id']}

    ${resp}=  AddCustomer  ${CUSERNAME5}    
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200


    ${firstName}=  FakerLibrary.name

    ${lastName}=  FakerLibrary.last_name
    ${email}=    FakerLibrary.Email


    ${resp}=    Send Otp For Login    ${CUSERNAME5}    ${accountId1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME5}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token1}  ${resp.json()['token']}

   
    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME5}    ${accountId1}  ${token1} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable    ${cid}   ${resp.json()['id']} 

    
    # ${cid}=  get_id  ${CUSERNAME5} 
    ${cnote}=   FakerLibrary.word
    ${resp}=  Add To Waitlist Consumers   ${cid}   ${account_id1}  ${que_id1}  ${CUR_DAY}  ${ser_id1}  ${cnote}  ${bool[0]}  ${self}  
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200 
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${wid1}  ${wid[0]}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    Set Suite Variable   ${invoiceLabel}

    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    Set Suite Variable   ${invoiceDate}

    ${invoiceId}=   FakerLibrary.word
    Set Suite Variable   ${invoiceId}
    
    ${quantity}=   Random Int  min=500  max=1000
    ${quantity}=  Convert To Number  ${quantity}  1
    ${servicecharge}=   Random Int  min=5  max=10


    ${serviceList}=  Create Dictionary  serviceId=${ser_id1}   quantity=${quantity}  price=${servicecharge}
    ${serviceList}=    Create List    ${serviceList}
    Set Suite Variable   ${serviceList}

    ${servicenetRate}=  Evaluate  ${quantity} * ${servicecharge}
    ${servicenetRate}=  Convert To Number  ${servicenetRate}   2
    Set Test Variable   ${servicenetRate}

    ${name1}=   FakerLibrary.word
    ${resp}=  Create Category   ${name1}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id}   ${resp.json()}
    
    ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${loc_id1}   serviceList=${serviceList}        ynwUuid=${wid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid3}   ${resp.json()['uidList'][0]}  

    ${resp1}=  Get Invoice By Id  ${invoice_uid3}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}

 
JD-TC-CreateInvoice-7

    [Documentation]  Again try to create invoice using that waitlist id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${loc_id1}   serviceList=${serviceList}        ynwUuid=${wid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp1}=  Get Booking Invoices  ${wid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()[0]['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()[0]['invoiceCategoryId']}  ${category_id}
    # Should Be Equal As Strings  ${resp1.json()[0]['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()[0]['invoiceDate']}  ${invoiceDate}


    Should Be Equal As Strings  ${resp1.json()[1]['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()[1]['invoiceCategoryId']}  ${category_id}
    # Should Be Equal As Strings  ${resp1.json()[1]['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()[1]['invoiceDate']}  ${invoiceDate}



JD-TC-CreateInvoice-8

    [Documentation]  Provider take one walkin Appointment and create invoice using that Appointment id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    # clear_appt_schedule   ${HLPUSERNAME1}

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
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}    ${parallel}  ${loc_id1}  ${duration}  ${bool1}  ${ser_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

    ${resp}=  Get Appointment Slots By Date Schedule  ${sch_id}  ${DAY1}  ${ser_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  scheduleName=${schedule_name}  scheduleId=${sch_id}
    Set Test Variable   ${slot1}   ${resp.json()['availableSlots'][0]['time']}

    ${resp}=  AddCustomer  ${CUSERNAME8} 
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${cid}   ${resp.json()}
    
    ${apptfor1}=  Create Dictionary  id=${cid}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}
    
    ${cnote}=   FakerLibrary.word
    ${resp}=  Take Appointment For Consumer  ${cid}  ${ser_id1}  ${sch_id}  ${DAY1}  ${cnote}  ${apptfor}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid}=  Get Dictionary Values  ${resp.json()}   sort_keys=False
    Set Suite Variable  ${apptid1}  ${apptid[0]}

    ${resp}=  Get Appointment EncodedID   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${encId}=  Set Variable   ${resp.json()}

    ${resp}=  Get Appointment By Id   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['uid']}   ${apptid1}

    ${resp}=  Create Invoice for Booking   ${invoicebooking[0]}   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    sleep   01s

    # ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}   ${invoiceLabel}   ${address}   ${vendor_uid1}   ${invoiceId}    ${providerConsumerIdList}   serviceList=${serviceList}        ynwUuid=${apptid1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${invoice_uid4}   ${resp.json()['uidList'][0]}  

    # ${resp}=   Get Locations 
    # Log  ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()[0]['accountId']}  ${account_id1}
    # Should Be Equal As Strings  ${resp1.json()[0]['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()[0]['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()[0]['billedTo']}  ${EMPTY}
    Should Be Equal As Strings  ${resp1.json()[0]['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp1.json()[0]['serviceList'][0]['serviceId']}  ${ser_id1}
    Should Be Equal As Strings  ${resp1.json()[0]['locationId']}  ${loc_id1}


    # ${resp1}=  Get Invoice By Id  ${invoice_uid4}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200
    # Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    # Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id}
    # # Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    # Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    # Should Be Equal As Strings  ${resp1.json()['invoiceLabel']}  ${invoiceLabel}
    # Should Be Equal As Strings  ${resp1.json()['billedTo']}  ${address}
    # Should Be Equal As Strings  ${resp1.json()['vendorUid']}  ${vendor_uid1}
    # # Should Be Equal As Strings  ${resp1.json()['invoiceId']}  ${invoiceId}
    # Should Be Equal As Strings  ${resp1.json()['ynwUuid']}  ${apptid1}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${ser_id1}
    # Should Be Equal As Strings  ${resp1.json()['locationId']}  ${loc_id1}

JD-TC-CreateInvoice-9

    [Documentation]  Provider take one online Appointment and create invoice using that Appointment id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Test Variable  ${account_id1}  ${resp.json()['id']}

    ${firstName}=  FakerLibrary.name

    ${lastName}=  FakerLibrary.last_name
    ${email}=    FakerLibrary.Email

    ${resp}=  AddCustomer  ${CUSERNAME3}    firstName=${firstName}   lastName=${lastname}  countryCode=${countryCodes[1]} 
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200



    ${resp}=    Send Otp For Login    ${CUSERNAME3}    ${accountId1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${CUSERNAME3}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token1}  ${resp.json()['token']}

   
    ${resp}=    ProviderConsumer Login with token   ${CUSERNAME3}    ${accountId1}  ${token1} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200



    # ${resp}=  Get Next Available Appointment Slots By ScheduleId  ${sch_id}   ${account_id1}
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
    # ${j}=  Random Int  max=${num_slots-1}
    # Set Test Variable   ${slot1}   ${slots[${j}]}

    # ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    # ${apptfor}=   Create List  ${apptfor1}

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${resp}=    Get All Schedule Slots By Date Location and Service  ${account_id1}  ${DAY1}  ${loc_id1}  ${ser_id1}
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
    ${j1}=  Random Int  max=${num_slots-1}
    Set Test Variable   ${slot1}   ${slots[${j1}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}


    ${cnote}=   FakerLibrary.name
    ${resp}=   Take Appointment For Provider   ${account_id1}  ${ser_id1}  ${sch_id}  ${DAY1}  ${cnote}   ${apptfor}    location=${loc_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get From Dictionary  ${resp.json()}  ${firstName}
    Set Suite Variable   ${apptid1}

    ${resp}=   Get consumer Appointment By Id   ${account_id1}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 


    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}    ${invoiceId}    ${providerConsumerIdList}   ${loc_id1}    serviceList=${serviceList}        ynwUuid=${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_uid4}   ${resp.json()['uidList'][0]}  

    ${resp1}=  Get Invoice By Id  ${invoice_uid4}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id}
    # Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    # Should Be Equal As Strings  ${resp1.json()['invoiceId']}  ${invoiceId}
    Should Be Equal As Strings  ${resp1.json()['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${ser_id1}
    Should Be Equal As Strings  ${resp1.json()['locationId']}  ${loc_id1}

JD-TC-CreateInvoice-10

    [Documentation]  Again try to create invoice using that Appointment id.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Create Invoice   ${category_id}    ${invoiceDate}     ${invoiceId}    ${providerConsumerIdList}   ${loc_id1}    serviceList=${serviceList}        ynwUuid=${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp1}=  Get Booking Invoices  ${apptid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
     Should Be Equal As Strings  ${resp1.json()[0]['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()[0]['invoiceCategoryId']}  ${category_id}
    # Should Be Equal As Strings  ${resp1.json()[0]['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()[0]['invoiceDate']}  ${invoiceDate}
    # Should Be Equal As Strings  ${resp1.json()[0]['invoiceId']}  ${invoiceId}
    Should Be Equal As Strings  ${resp1.json()[0]['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp1.json()[0]['serviceList'][0]['serviceId']}  ${ser_id1}
    # Should Be Equal As Strings  ${resp1.json()[0]['locationId']}  ${loc_id1}

     Should Be Equal As Strings  ${resp1.json()[1]['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()[1]['invoiceCategoryId']}  ${category_id}
    # Should Be Equal As Strings  ${resp1.json()[1]['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()[1]['invoiceDate']}  ${invoiceDate}
    # Should Be Equal As Strings  ${resp1.json()[1]['invoiceId']}  ${invoiceId}
    Should Be Equal As Strings  ${resp1.json()[1]['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp1.json()[1]['serviceList'][0]['serviceId']}  ${ser_id1}
    # Should Be Equal As Strings  ${resp1.json()[0]['locationId']}  ${loc_id1}


JD-TC-CreateInvoice-11

    [Documentation]  Taking waitlist from consumer side and the consumer doing the prepayment - check invoice(auto-invoice generation flag is on) (Tax enabled)

    ${firstname}  ${lastname}  ${PUSERPH1}  ${LoginId}=  Provider Signup
    Set Suite Variable  ${PUSERPH1}   


    
    # ------------- Get general details and settings of the provider and update all needed settings
    
    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${pid1}  ${resp.json()['id']}
    Set Suite Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${DAY}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY}  

    ${resp}=   Get License UsageInfo 
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Verify Response  ${resp}  onlineCheckIns=${bool[1]}

    ${resp}=  Enable Waitlist
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${resp1}=   Run Keyword If  ${resp.json()['onlinePresence']}==${bool[0]}   Set jaldeeIntegration Settings    ${boolean[1]}  ${boolean[1]}  ${EMPTY}
    Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.content}
    Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['walkinConsumerBecomesJdCons']}   ${bool[1]}

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END
    
    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

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
    Set Suite Variable  ${accountId1}  ${resp.json()['accountId']}    
    

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${GST_num}  ${pan_num}=   db.Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstpercentage[3]}  ${GST_num} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    
    ${resp}=  Enable Tax
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    
    ${p1_lid}=  Create Sample Location
    ${resp}=  Get Locations
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_lid}  ${resp.json()[0]['id']} 

    ${min_pre}=   Random Int   min=40   max=50
    ${Tot}=   Random Int   min=100   max=300
    ${min_pre}=   Convert To Integer   ${min_pre}  
    Set Suite Variable   ${min_pre}
    # ${pre_float}=  twodigitfloat  ${min_pre}
    ${Tot1}=  Convert To Integer  ${Tot}  
    Set Suite Variable   ${Tot}   ${Tot1}

    ${P1SERVICE1}=    FakerLibrary.word
    Set Suite Variable   ${P1SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${maxBookingsAllowed}=   Random Int   min=2   max=5
    #
    ${resp}=  Create Service  ${P1SERVICE1}  ${desc}  ${service_duration1}  ${bool[1]}  ${Tot}  ${bool[1]}    minPrePaymentAmount=${min_pre}   maxBookingsAllowed=${maxBookingsAllowed}   prePaymentType=${advancepaymenttype[1]}   automaticInvoiceGeneration=${bool[1]}   taxable=${bool[1]} 
    # ${resp}=  Create Service  ${P1SERVICE1}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${min_pre}  ${Tot}  ${bool[1]}  ${bool[1]}    maxBookingsAllowed=${maxBookingsAllowed}   prePaymentType=${advancepaymenttype[1]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_sid1}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid1}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}


    ${P1SERVICE2}=    FakerLibrary.word
    Set Suite Variable   ${P1SERVICE2} 
    ${desc}=   FakerLibrary.sentence
    ${resp}=  Create Service  ${P1SERVICE2}  ${desc}  ${service_duration1}  ${bool[0]}  ${Tot}  ${bool[1]}    automaticInvoiceGeneration=${bool[1]}
    # ${resp}=  Create Service  ${P1SERVICE2}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${EMPTY}  ${Tot}  ${bool[0]}  ${bool[1]}   
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_sid2}  ${resp.json()}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Integer  ${quantity}  
    ${serviceprice}=   Random Int  min=100  max=500
    ${serviceprice}=  Convert To Integer  ${serviceprice}  
    ${serviceList1}=  Create Dictionary  serviceId=${p1_sid2}   quantity=${quantity}   price=${serviceprice} 

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid2}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    ${queue1}=    FakerLibrary.word
    ${capacity}=  FakerLibrary.Numerify  %%
    ${sTime}=  add_timezone_time  ${tz}  2  00  
    ${eTime}=  add_timezone_time  ${tz}  2  15  
    ${parallel}=   Random Int  min=1   max=1
    ${resp}=  Create Queue  ${queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime}  ${eTime}  ${parallel}  ${capacity}  ${p1_lid}  ${p1_sid1}  ${p1_sid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_qid}  ${resp.json()}


    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200



    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Consumer Login  ${CUSERNAME6}  ${PASSWORD}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    # ${cid1}=  get_id  ${CUSERNAME6}
    # Set Suite Variable   ${cid1}

    ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo}
    ${email}=    FakerLibrary.Email
    Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${accountId1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    # ${resp}=    Consumer Logout  
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo}     ${accountId1}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['id']}


    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Add To Waitlist Consumers   ${cid1}   ${pid1}  ${p1_qid}  ${DAY}  ${p1_sid1}  ${msg}  ${bool[0]}  ${self}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${cwid}  ${wid[0]} 
    
    ${tax1}=  Evaluate  ${Tot}*${gstpercentage[3]}
    ${tax}=   Evaluate  ${tax1}/100
    ${tax}=  Convert To Integer  ${tax}  
    ${totalamt}=  Evaluate  ${Tot}+${tax}
    ${totalamt}=  Convert To Integer  ${totalamt}  
    ${balamount}=  Evaluate  ${totalamt}-${min_pre}
    ${balamount}=  Convert To Integer  ${balamount}  

    #sleep  01s

    ${resp}=  Get consumer Waitlist By Id  ${cwid}  ${pid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[0]}   waitlistStatus=${wl_status[3]}


    #sleep   01s

    ${resp}=  Make payment Consumer Mock  ${pid1}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Make payment Consumer Mock  ${min_pre}  ${bool[1]}  ${cwid}  ${pid}  ${purpose[0]}  ${cid1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}

    ${resp}=  Encrypted Provider Login  ${PUSERPH1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp1}=  Get consumer Waitlist Bill Details   ${cwid}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200

    #sleep   01s
    
    ${resp}=  Get Booking Invoices  ${cwid}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
   ${service_response_price}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['price']} 
   ${service_response_netRate}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['netRate']} 
   ${response_amountPaid}=  Convert To Integer  ${resp.json()[0]['amountPaid']}
   ${response_amountDue}=  Convert To Integer  ${resp.json()[0]['amountDue']}
   ${response_amountTotal}=  Convert To Integer  ${resp.json()[0]['amountTotal']}
#    ${response_taxPercentage}=  Convert To Integer  ${resp.json()[0]['taxPercentage']}
   ${response_defaultCurrencyAmount}=  Convert To Integer  ${resp.json()[0]['defaultCurrencyAmount']}
   ${response_netTaxAmount}=  Convert To Integer  ${resp.json()[0]['netTaxAmount']}
   ${response_netTotal}=  Convert To Integer  ${resp.json()[0]['netTotal']}
   ${response_netRate}=  Convert To Integer  ${resp.json()[0]['netRate']}
   ${response_taxableTotal}=  Convert To Integer  ${resp.json()[0]['taxableTotal']}

    Should Be Equal As Strings   ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid1}
    Should Be Equal As Strings   ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE1}
    Should Be Equal As Strings   ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings   ${service_response_price}   ${Tot}
    Should Be Equal As Strings   ${service_response_netRate}  ${Tot}
    Should Be Equal As Strings   ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre}
    Should Be Equal As Strings   ${response_amountDue}  ${balamount}
    Should Be Equal As Strings   ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}   ${Tot}
    Should Be Equal As Strings   ${response_netTaxAmount}  ${tax}
    Should Be Equal As Strings   ${response_netTotal}  ${Tot}
    Should Be Equal As Strings   ${response_netRate}  ${totalamt}
    Should Be Equal As Strings   ${response_taxableTotal}  ${Tot}
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid}
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot}
    Set Suite Variable  ${invoice_wtlistonline_uid}  ${resp.json()[0]['invoiceUid']}

    FOR   ${a}  IN RANGE   15
       
        ${resp}=  Flush Analytics Data to DB
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        sleep  01s
        Exit For Loop If    ${resp.content}=="FREE"
    
    END
    #Finance Invoice Partially Paid Count
    ${resp}=  Get Finance Analytics  frequency=${dateCategory[0]}   accId=${pid1}   locationId=${p1_lid}     metricId=166    
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

JD-TC-CreateInvoice-12

    [Documentation]  Taking waitlist from consumer side and the consumer doing the prepayment and then did full payment - check invoice(auto-invoice generation flag is on) (Tax enabled)

   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Add To Waitlist Consumers   ${cid1}   ${pid1}  ${p1_qid}  ${DAY}  ${p1_sid1}  ${msg}  ${bool[0]}  ${self}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${cwid1}  ${wid[0]} 
    
    ${tax1}=  Evaluate  ${Tot}*${gstpercentage[3]}
    ${tax}=   Evaluate  ${tax1}/100
    ${tax}=   Convert To Integer  ${tax}  
    ${totalamt}=  Evaluate  ${Tot}+${tax}
    ${totalamt}=   Convert To Integer  ${totalamt}  
    # ${totalamt}=  Evaluate  "%.2f" % ${totalamt}
    # ${totalamt}=  twodigitfloat  ${totalamt}
    ${balamount}=  Evaluate  ${totalamt}-${min_pre}
    ${balamount}=   Convert To Integer  ${balamount}  


    ${resp}=  Get consumer Waitlist By Id  ${cwid1}  ${pid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[0]}   waitlistStatus=${wl_status[3]}


    #sleep   01s

    ${resp}=  Make payment Consumer Mock  ${pid1}  ${min_pre}  ${purpose[0]}  ${cwid1}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Make payment Consumer Mock  ${min_pre}  ${bool[1]}  ${cwid}  ${pid}  ${purpose[0]}  ${cid1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}



    ${resp}=  Encrypted Provider Login  ${PUSERPH1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp1}=  Get consumer Waitlist Bill Details   ${cwid1}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    sleep   01s
    ${resp}=  Get Booking Invoices  ${cwid1}
    Log  ${resp.content}
   ${service_response_price}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['price']} 
   ${service_response_netRate}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['netRate']} 
   ${response_amountPaid}=  Convert To Integer  ${resp.json()[0]['amountPaid']}
   ${response_amountDue}=  Convert To Integer  ${resp.json()[0]['amountDue']}
   ${response_amountTotal}=  Convert To Integer  ${resp.json()[0]['amountTotal']}
   ${response_defaultCurrencyAmount}=  Convert To Integer  ${resp.json()[0]['defaultCurrencyAmount']}
   ${response_netTaxAmount}=  Convert To Integer  ${resp.json()[0]['netTaxAmount']}
   ${response_netTotal}=  Convert To Integer  ${resp.json()[0]['netTotal']}
   ${response_netRate}=  Convert To Integer  ${resp.json()[0]['netRate']}
   ${response_taxableTotal}=  Convert To Integer  ${resp.json()[0]['taxableTotal']}

    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid1}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${service_response_price}   ${Tot}
    Should Be Equal As Strings  ${service_response_netRate}  ${Tot}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid1}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre}
    Should Be Equal As Strings  ${response_amountDue}  ${balamount}
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}  ${Tot}
    Should Be Equal As Strings  ${response_netTaxAmount}  ${tax}
    Should Be Equal As Strings  ${response_netTotal}  ${Tot}
    Should Be Equal As Strings  ${response_netRate}  ${totalamt}
    Should Be Equal As Strings   ${response_taxableTotal}  ${Tot}
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid1}
    Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[1]}
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot}
    Set Suite Variable  ${invoice_wtlistonline_uid1}  ${resp.json()[0]['invoiceUid']}

    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=  Get consumer Waitlist By Id  ${cwid1}  ${pid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[1]}   waitlistStatus=${wl_status[0]}

    #sleep   02s

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_wtlistonline_uid1}  ${balamount}   ${purpose[6]}    ${source}  ${pid1}   ${finance_payment_modes[8]}  ${bool[0]}   ${p1_sid1}   ${cid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    # ${resp}=  Make payment Consumer Mock  ${pid1}  ${balamount}  ${purpose[1]}  ${cwid1}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${None}
    # Log  ${resp.json()}


    ${resp}=  Encrypted Provider Login  ${PUSERPH1}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    FOR   ${a}  IN RANGE   15
       
        ${resp}=  Flush Analytics Data to DB
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        sleep  01s
        Exit For Loop If    ${resp.content}=="FREE"
    
    END
    #Finance Invoice Paid Total
    ${resp}=  Get Finance Analytics  frequency=${dateCategory[0]}   accId=${pid1}   locationId=${p1_lid}     metricId=180    
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    #Finance Invoice Due Total
    ${resp}=  Get Finance Analytics  frequency=${dateCategory[0]}   accId=${pid1}   locationId=${p1_lid}     metricId=181   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    #Finance Invoice Count
    ${resp}=  Get Finance Analytics  frequency=${dateCategory[0]}   accId=${pid1}   locationId=${p1_lid}     metricId=160   
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}   name-eq=${Booking} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable   ${categ_id1}   ${resp.json()[0]['id']}



    # ${resp1}=  Get Invoice By Id  ${invoice_wtlistonline_uid1}
    # Log  ${resp1.content}
    # ${response1_netTotal}=  Convert To Integer  ${resp1.json()['netTotal']}
    # ${response1_netRate}=  Convert To Integer  ${resp1.json()['netRate']}
    # ${response1_amountTotal}=  Convert To Integer  ${resp1.json()['amountTotal']}

    # Should Be Equal As Strings  ${resp1.status_code}  200
    # Should Be Equal As Strings  ${resp1.json()['accountId']}  ${pid1}
    # Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${categ_id1}
    # Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${Booking}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${p1_sid1}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  1.0
    # Should Be Equal As Strings  ${response1_netTotal}  ${Tot}
    # Should Be Equal As Strings  ${response1_netRate}  ${totalamt}
    # Should Be Equal As Strings   ${response1_amountTotal}  ${Tot}
    # Should Be Equal As Strings  ${resp1.json()['amountDue']}  0
    # Should Be Equal As Strings  ${resp1.json()['billPaymentStatus']}  ${paymentStatus[2]}

    ${resp}=  Get Booking Invoices  ${cwid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid1}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE1}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${service_response_price}   ${Tot}
    Should Be Equal As Strings  ${service_response_netRate}  ${Tot}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid1}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre}
    Should Be Equal As Strings  ${response_amountDue}  0
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}  ${Tot}
    Should Be Equal As Strings  ${response_netTaxAmount}  ${tax}
    Should Be Equal As Strings  ${response_netTotal}  ${Tot}
    Should Be Equal As Strings  ${response_netRate}  ${totalamt}
    Should Be Equal As Strings   ${response_taxableTotal}  ${Tot}
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid1}
    Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[2]}
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot}




    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid1}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE1}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['price']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['netRate']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid1}
    # Should Be Equal As Strings  ${resp.json()[0]['amountPaid']}  ${min_pre}
    # Should Be Equal As Strings  ${resp.json()[0]['amountTotal']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    # Should Be Equal As Strings  ${resp.json()[0]['defaultCurrencyAmount']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['netTaxAmount']}  ${tax}
    # Should Be Equal As Strings  ${resp.json()[0]['netTotal']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['netRate']}  ${totalamt}
    # Should Be Equal As Strings  ${resp.json()[0]['taxableTotal']}  ${Tot}
    # Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid1}
    # Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[2]}
    # Should Be Equal As Strings  ${resp.json()[0]['amountDue']}  0

JD-TC-CreateInvoice-13

    [Documentation]  Taking waitlist from consumer side and the consumer doing the prepayment - check invoice(auto-invoice generation flag is on) (Tax Disabled)

   
    ${firstname}  ${lastname}  ${PUSERPH2}  ${LoginId}=  Provider Signup
    Set Suite Variable  ${PUSERPH2}

    
    # ------------- Get general details and settings of the provider and update all needed settings
    
    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${pid2}  ${resp.json()['id']}
    Set Suite Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${DAY}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY}  

    ${resp}=   Get License UsageInfo 
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Verify Response  ${resp}  onlineCheckIns=${bool[1]}

    ${resp}=  Enable Waitlist
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${resp1}=   Run Keyword If  ${resp.json()['onlinePresence']}==${bool[0]}   Set jaldeeIntegration Settings    ${boolean[1]}  ${boolean[1]}  ${EMPTY}
    Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.content}
    Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['walkinConsumerBecomesJdCons']}   ${bool[1]}

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END
    
    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

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
    Set Suite Variable  ${accountId2}  ${resp.json()['accountId']}    
    

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    
    ${p1_lid}=  Create Sample Location
    ${resp}=  Get Locations
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_lid}  ${resp.json()[0]['id']} 

    ${min_pre1}=   Random Int   min=40   max=50
    ${Tot}=   Random Int   min=100   max=300
    ${min_pre1}=   Convert To Integer  ${min_pre1}  
    Set Suite Variable   ${min_pre1}
    # ${pre_float}=  twodigitfloat  ${min_pre}
    ${Tot11}=   Convert To Integer  ${Tot}   
    Set Suite Variable   ${Tot2}   ${Tot11}

    ${P1SERVICE11}=    FakerLibrary.word
    Set Suite Variable   ${P1SERVICE11}
    ${desc}=   FakerLibrary.sentence
    ${maxBookingsAllowed}=   Random Int   min=2   max=5
    ${resp}=  Create Service  ${P1SERVICE11}  ${desc}  ${service_duration1}  ${bool[1]}  ${Tot2}  ${bool[1]}    minPrePaymentAmount=${min_pre1}   maxBookingsAllowed=${maxBookingsAllowed}   automaticInvoiceGeneration=${bool[1]}  
    # ${resp}=  Create Service  ${P1SERVICE11}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${min_pre1}  ${Tot2}  ${bool[1]}  ${bool[0]}    maxBookingsAllowed=${maxBookingsAllowed}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_sid11}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid11}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid11}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}


    ${list}=  Create List   1  2  3  4  5  6  7
    ${queue1}=    FakerLibrary.word
    ${capacity}=  FakerLibrary.Numerify  %%
    ${sTime}=  add_timezone_time  ${tz}  2  00  
    ${eTime}=  add_timezone_time  ${tz}  2  15  
    ${parallel}=   Random Int  min=1   max=1
    ${resp}=  Create Queue  ${queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime}  ${eTime}  ${parallel}  ${capacity}  ${p1_lid}  ${p1_sid11}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_qid1}  ${resp.json()}


    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}  
    Log  ${resp.json()}


    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200



    ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo1}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo1}
    ${email}=    FakerLibrary.Email
    Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo1}    ${accountId2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo1}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo1}     ${accountId2}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo1}    ${accountId2}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Add To Waitlist Consumers   ${cid1}   ${pid2}  ${p1_qid1}  ${DAY}  ${p1_sid11}  ${msg}  ${bool[0]}  ${self}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${cwid3}  ${wid[0]} 
    

    ${balamount}=  Evaluate  ${Tot2}-${min_pre1}
    ${balamount}=   Convert To Integer  ${balamount}  

    #sleep   02s

    ${resp}=  Get consumer Waitlist By Id  ${cwid3}  ${pid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[0]}   waitlistStatus=${wl_status[3]}


    #sleep   02s

    ${resp}=  Make payment Consumer Mock  ${pid2}  ${min_pre1}  ${purpose[0]}  ${cwid3}  ${p1_sid11}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}

    #sleep   02s

    ${resp}=  Encrypted Provider Login  ${PUSERPH2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp1}=  Get consumer Waitlist Bill Details   ${cwid3}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200
    ${resp}=   Get Service By Id  ${p1_sid11}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    #sleep   01s
    ${resp}=  Get Booking Invoices  ${cwid3}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

   ${service_response_price}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['price']} 
   ${service_response_netRate}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['netRate']} 
   ${response_amountPaid}=  Convert To Integer  ${resp.json()[0]['amountPaid']}
   ${response_amountDue}=  Convert To Integer  ${resp.json()[0]['amountDue']}
   ${response_amountTotal}=  Convert To Integer  ${resp.json()[0]['amountTotal']}
   ${response_defaultCurrencyAmount}=  Convert To Integer  ${resp.json()[0]['defaultCurrencyAmount']}
   ${response_netTaxAmount}=  Convert To Integer  ${resp.json()[0]['netTaxAmount']}
   ${response_netTotal}=  Convert To Integer  ${resp.json()[0]['netTotal']}
   ${response_netRate}=  Convert To Integer  ${resp.json()[0]['netRate']}
   ${response_taxableTotal}=  Convert To Integer  ${resp.json()[0]['taxableTotal']}

    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid11}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${service_response_price}   ${Tot2}
    Should Be Equal As Strings  ${service_response_netRate}  ${Tot2}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid3}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre1}
    Should Be Equal As Strings  ${response_amountDue}  ${balamount}
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  0.0
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}  ${Tot2}
    Should Be Equal As Strings  ${response_netTaxAmount}  0
    Should Be Equal As Strings  ${response_netTotal}  ${Tot2}
    Should Be Equal As Strings  ${response_netRate}  ${Tot2}
    Should Be Equal As Strings   ${response_taxableTotal}  0
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid3}
    Set Suite Variable  ${invoice_wtlistonline_uid2}  ${resp.json()[0]['invoiceUid']}
    Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[1]}
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot2}


    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid11}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['price']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid3}
    # Should Be Equal As Strings  ${resp.json()[0]['amountPaid']}  ${min_pre1}
    # Should Be Equal As Strings  ${resp.json()[0]['amountDue']}  ${balamount}
    # Should Be Equal As Strings  ${resp.json()[0]['amountTotal']}  ${Tot2}
    # # Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    # Should Be Equal As Strings  ${resp.json()[0]['defaultCurrencyAmount']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netTaxAmount']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['netTotal']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['taxableTotal']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid3}
    # Set Suite Variable  ${invoice_wtlistonline_uid2}  ${resp.json()[0]['invoiceUid']}

JD-TC-CreateInvoice-14

    [Documentation]  Taking waitlist from consumer side and the consumer doing the prepayment and did full payment - check invoice(auto-invoice generation flag is on) (Tax Disabled)

   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo1}    ${accountId2}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Add To Waitlist Consumers  ${cid1}  ${pid2}  ${p1_qid1}  ${DAY}  ${p1_sid11}  ${msg}  ${bool[0]}  ${self}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${cwid4}  ${wid[0]} 
    

    ${balamount}=  Evaluate  ${Tot2}-${min_pre1}
    ${balamount}=   Convert To Integer  ${balamount}  



    ${resp}=  Get consumer Waitlist By Id  ${cwid4}  ${pid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[0]}   waitlistStatus=${wl_status[3]}


    #sleep   02s

    ${resp}=  Make payment Consumer Mock  ${pid2}  ${min_pre1}  ${purpose[0]}  ${cwid4}  ${p1_sid11}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}

    # sleep   02s

    ${resp}=  Encrypted Provider Login  ${PUSERPH2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp1}=  Get consumer Waitlist Bill Details   ${cwid4}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200
    #sleep   02s
    ${resp}=   Get Service By Id  ${p1_sid11}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  Get Booking Invoices  ${cwid4}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${service_response_price}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['price']} 
    ${service_response_netRate}=  Convert To Integer  ${resp.json()[0]['serviceList'][0]['netRate']} 
    ${response_amountPaid}=  Convert To Integer  ${resp.json()[0]['amountPaid']}
    ${response_amountDue}=  Convert To Integer  ${resp.json()[0]['amountDue']}
    ${response_amountTotal}=  Convert To Integer  ${resp.json()[0]['amountTotal']}
    ${response_defaultCurrencyAmount}=  Convert To Integer  ${resp.json()[0]['defaultCurrencyAmount']}
    ${response_netTaxAmount}=  Convert To Integer  ${resp.json()[0]['netTaxAmount']}
    ${response_netTotal}=  Convert To Integer  ${resp.json()[0]['netTotal']}
    ${response_netRate}=  Convert To Integer  ${resp.json()[0]['netRate']}
    ${response_taxableTotal}=  Convert To Integer  ${resp.json()[0]['taxableTotal']}

    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid11}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${service_response_price}   ${Tot2}
    Should Be Equal As Strings  ${service_response_netRate}  ${Tot2}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid4}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre1}
    Should Be Equal As Strings  ${response_amountDue}  ${balamount}
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  0.0
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}  ${Tot2}
    Should Be Equal As Strings  ${response_netTaxAmount}  0
    Should Be Equal As Strings  ${response_netTotal}  ${Tot2}
    Should Be Equal As Strings  ${response_netRate}  ${Tot2}
    Should Be Equal As Strings   ${response_taxableTotal}  0
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot2}
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid4}
    Set Suite Variable  ${invoice_wtlistonline_uid}  ${resp.json()[0]['invoiceUid']}

    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid11}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['price']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid4}
    # Should Be Equal As Strings  ${resp.json()[0]['amountPaid']}  ${min_pre1}
    # Should Be Equal As Strings  ${resp.json()[0]['amountDue']}  ${balamount}
    # Should Be Equal As Strings  ${resp.json()[0]['amountTotal']}  ${Tot2}
    # # Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  ${gstpercentage[3]}
    # Should Be Equal As Strings  ${resp.json()[0]['defaultCurrencyAmount']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netTaxAmount']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['netTotal']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['taxableTotal']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid4}
    # Set Suite Variable  ${invoice_wtlistonline_uid}  ${resp.json()[0]['invoiceUid']}

    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo1}    ${accountId2}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    #sleep  2s

    # ${resp}=  Get consumer Waitlist By Id  ${cwid4}  ${pid1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Verify Response  ${resp}  paymentStatus=${paymentStatus[1]}   waitlistStatus=${wl_status[0]}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_wtlistonline_uid}  ${balamount}   ${purpose[6]}    ${source}  ${pid2}   ${finance_payment_modes[8]}  ${bool[0]}   ${p1_sid11}   ${cid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    # ${resp}=  Make payment Consumer Mock  ${pid2}  ${balamount}  ${purpose[1]}  ${cwid4}  ${p1_sid11}  ${bool[0]}   ${bool[1]}  ${None}
    # Log  ${resp.json()}

    # sleep   02s
    ${resp}=  Encrypted Provider Login  ${PUSERPH2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp1}=  Get Invoice By Id  ${invoice_wtlistonline_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=  Get Booking Invoices  ${cwid4}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

   
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${service_response_price}   ${Tot2}
    Should Be Equal As Strings  ${service_response_netRate}  ${Tot2}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid4}
    Should Be Equal As Strings   ${response_amountPaid}   ${min_pre1}
    Should Be Equal As Strings  ${response_amountDue}  ${balamount}
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  0.0
    Should Be Equal As Strings   ${response_defaultCurrencyAmount}  ${Tot2}
    Should Be Equal As Strings  ${response_netTaxAmount}  0
    Should Be Equal As Strings  ${response_netTotal}  ${Tot2}
    Should Be Equal As Strings  ${response_netRate}  ${Tot2}
    Should Be Equal As Strings   ${response_taxableTotal}  0
    Should Be Equal As Strings   ${response_amountTotal}  ${Tot2}
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid4}
    Should Be Equal As Strings  ${response_amountDue}  0
    Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[2]}


    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE11}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['price']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${cwid4}
    # Should Be Equal As Strings  ${resp.json()[0]['amountPaid']}  ${min_pre1}
    # Should Be Equal As Strings  ${resp.json()[0]['amountTotal']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['defaultCurrencyAmount']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netTaxAmount']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['netTotal']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['netRate']}  ${Tot2}
    # Should Be Equal As Strings  ${resp.json()[0]['taxableTotal']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${cwid4}
    # Should Be Equal As Strings  ${resp.json()[0]['amountDue']}  0.0
    # Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[2]}
# *** Comments ***



JD-TC-CreateInvoice-15

    [Documentation]  Create a invoice and share via link then consumer paid some amount of that invoice.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${decrypted_data}=  db.decrypt_data   ${resp.content}
    Log  ${decrypted_data}

    Set Suite Variable  ${pid}  ${decrypted_data['id']}
    Set Suite Variable    ${pdrname}    ${decrypted_data['userName']}
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


    ${resp}=  Create Sample Location  
    Set Suite Variable    ${lid1}    ${resp}  

    ${resp}=   Get Location ById  ${lid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}


    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${lid}   ${resp.json()[1]['id']}

    ${name}=   FakerLibrary.word
    Set Suite Variable   ${name}
 
    ${resp}=  CreateVendorCategory  ${name}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id}   ${resp.json()}

    ${resp}=  Get by encId  ${category_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}

    ${name}=   FakerLibrary.word
    ${resp}=  Create Category   ${name}  ${categoryType[1]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id1}   ${resp.json()}

    ${name1}=   FakerLibrary.word
    Set Suite Variable   ${name1}
    ${resp}=  Create Category   ${name1}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${category_id2}   ${resp.json()}

    ${resp}=  Get Category By Id   ${category_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['name']}          ${name}
    Should Be Equal As Strings  ${resp.json()['categoryType']}  ${categoryType[1]}
    Should Be Equal As Strings  ${resp.json()['accountId']}     ${account_id1}
    Should Be Equal As Strings  ${resp.json()['status']}        ${toggle[0]}



    ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo}
    ${email}=    FakerLibrary.Email
    Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${accountId1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo}     ${accountId1}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${pcid18}    ${resp.json()['providerConsumer']}

    ${providerConsumerIdList}=  Create List  ${pcid18}
    Set Suite Variable  ${providerConsumerIdList}   

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${referenceNo}=   Random Int  min=5  max=200
    ${referenceNo}=  Convert To String  ${referenceNo}

    ${description}=   FakerLibrary.word
    # Set Suite Variable  ${address}
    ${invoiceLabel}=   FakerLibrary.word
    Set Suite Variable  ${invoiceLabel} 

    ${invoiceDate}=   db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${invoiceDate} 

    # ${invoiceDate}=   Get Current Date    result_format=%Y/%m/%d
    ${resp}=   Get next invoice Id   ${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoiceId}   ${resp.json()}

    ${item1}=     FakerLibrary.word
    ${itemCode1}=     FakerLibrary.word
    ${price1}=     Random Int   min=400   max=500
    ${price}=  Convert To Number  ${price1}  1
    Set Suite Variable  ${price} 
    ${resp}=  Create Sample Item   ${DisplayName1}   ${item1}  ${itemCode1}  ${price}  ${bool[1]} 
    Log  ${resp.json()}  
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${itemId}  ${resp.json()}

    ${resp}=   Get Item By Id  ${itemId}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${promotionalPrice}   ${resp.json()['promotionalPrice']}


    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    Set Suite Variable  ${quantity}
    ${itemList}=  Create Dictionary  itemId=${itemId}   quantity=${quantity}   price=${promotionalPrice}
    Set Suite Variable  ${itemList}
    # ${itemList}=    Create List    ${itemList}

    ${resp}=  Create Finance Status   ${New_status[0]}  ${categoryType[3]} 
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${status_id1}   ${resp.json()}

    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${serviceprice}=   Random Int  min=10  max=15
    ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${resp}=  Create Service  ${SERVICE1}  ${desc}  ${service_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}   
    # ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid1}  ${resp.json()}

    ${serviceList}=  Create Dictionary  serviceId=${sid1}   quantity=${quantity}  price=${serviceprice}
    ${serviceList}=    Create List    ${serviceList}
    Set Suite Variable  ${serviceList}


    ${itemName}=    FakerLibrary.word
    Set Suite Variable  ${itemName}
    ${price}=   Random Int  min=10  max=15
    ${price2}=  Convert To Number  ${price}  1
    Set Suite Variable  ${price2}
    ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price2}
    ${adhocItemList}=    Create List    ${adhocItemList}
    Set Suite Variable  ${adhocItemList}

    ${nonTaxableTotal}=    Evaluate  ${price2}*${quantity}+${serviceprice}*${quantity}
    Set Suite Variable  ${nonTaxableTotal}

    ${taxableTotal}=    Evaluate  ${promotionalPrice}*${quantity}
    Set Suite Variable  ${taxableTotal}

    ${netTotal}=    Evaluate  ${nonTaxableTotal}+${taxableTotal}
    Set Suite Variable  ${netTotal}
    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}      ${invoiceId}    ${providerConsumerIdList}   ${lid1}    ${itemList}  invoiceStatus=${status_id1}    serviceList=${serviceList}   adhocItemList=${adhocItemList}   locationId=${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_id}   ${resp.json()['idList'][0]}
    Set Suite Variable   ${invoice_uid}   ${resp.json()['uidList'][0]}    

    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid1}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price2}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}  ${nonTaxableTotal}
    Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${netTotal}

    ${PO_Number}    Generate random string    5    123456789
    ${vendor_phn}=  Evaluate  ${PUSERNAME}+${PO_Number}
    Set Suite Variable  ${vendor_phn} 
    Set Suite Variable  ${email}  ${item1}${vendor_phn}.${test_mail}

    ${resp}=  Generate Link For Invoice  ${invoice_uid}   ${primaryMobileNo}    ${email}    ${boolean[1]}    ${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Service payment modes    ${pid}    ${sid1}    ${purpose[6]}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()[0]['isJaldeeBank']}    ${bool[1]}
    Set Suite Variable    ${proid}  ${resp.json()[0]['profileId']}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_uid}  ${nonTaxableTotal}   ${purpose[6]}    ${source}  ${pid}   ${finance_payment_modes[8]}  ${bool[0]}   ${sid1}   ${pcid18}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${bal_netTotal}=    Evaluate  ${netTotal}-${nonTaxableTotal}


    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid1}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price2}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}  ${nonTaxableTotal}
    Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${bal_netTotal}

JD-TC-CreateInvoice-16

    [Documentation]  Create a invoice and share via link then consumer paid full amount of that invoice.


    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Service payment modes    ${pid}    ${sid1}    ${purpose[6]}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()[0]['isJaldeeBank']}    ${bool[1]}
    Set Suite Variable    ${proid}  ${resp.json()[0]['profileId']}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_uid}  ${nonTaxableTotal}   ${purpose[6]}    ${source}  ${pid}   ${finance_payment_modes[8]}  ${bool[0]}   ${sid1}   ${pcid18}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # ${bal_netTotal}=    Evaluate  ${netTotal}-${nonTaxableTotal}


    ${resp1}=  Get Invoice By Id  ${invoice_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid1}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['itemName']}  ${itemName}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['adhocItemList'][0]['price']}  ${price2}
    Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}  ${nonTaxableTotal}
    Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  0


JD-TC-CreateInvoice-17

    [Documentation]  Create a invoice with tax enable, then do a prepayment.

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${GST_num}  ${pan_num}=   db.Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstpercentage[3]}  ${GST_num} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    
    ${resp}=  Enable Tax
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${SERVICE1}=    generate_unique_service_name  ${service_names}
    Set Suite Variable  ${SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${servicecharge}=   Random Int  min=100  max=500
    ${serviceprice}=   Random Int  min=10  max=15
    ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${resp}=  Create Service  ${SERVICE1}  ${desc}  ${service_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}   
    # ${resp}=  Create Service  ${SERVICE1}  ${desc}   ${srv_duration}  ${bool[0]}  ${servicecharge}  ${bool[0]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sid2}  ${resp.json()}

    ${serviceList}=  Create Dictionary  serviceId=${sid2}   quantity=${quantity}  price=${serviceprice}
    ${serviceList}=    Create List    ${serviceList}


    # ${itemName}=    FakerLibrary.word
    # Set Suite Variable  ${itemName}
    # ${price}=   Random Int  min=10  max=15
    # ${price}=  Convert To Number  ${price}  1
    # ${adhocItemList}=  Create Dictionary  itemName=${itemName}   quantity=${quantity}   price=${price}
    # ${adhocItemList}=    Create List    ${adhocItemList}

    ${nonTaxableTotal}=    Evaluate  ${serviceprice}*${quantity}
    ${nonTaxableTotal}=  Convert To Number  ${nonTaxableTotal}  2
    Set Suite Variable  ${nonTaxableTotal}

    ${taxableTotal}=    Evaluate  ${promotionalPrice}*${quantity}
    ${taxableTotal}=  Convert To Number  ${taxableTotal}  2
    Set Suite Variable  ${taxableTotal}

    ${netTotal}=    Evaluate  ${nonTaxableTotal}+${taxableTotal}
    ${netTotal}=  Convert To Number  ${netTotal}  2
    Set Suite Variable  ${netTotal}

    ${tax1}=  Evaluate  ${taxableTotal}*${gstpercentage[3]}
    ${tax}=   Evaluate  ${tax1}/100
    ${tax}=  Convert To Number  ${tax}  2

    ${totalamt}=  Evaluate  ${netTotal}+${tax}
    ${totalamt}=  twodigitfloat  ${totalamt}
    # ${totalamt}=  Evaluate  round(${totalamt})
    
    ${resp}=  Create Invoice   ${category_id2}    ${invoiceDate}     ${invoiceId}    ${providerConsumerIdList}   ${lid1}   ${itemList}  invoiceStatus=${status_id1}    serviceList=${serviceList}      locationId=${lid}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${invoice_id}   ${resp.json()['idList'][0]}
    Set Suite Variable   ${invoice_uid1}   ${resp.json()['uidList'][0]}    

    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    # Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    # Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    # Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    # Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid2}
    # Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    # Should Be Equal As Strings  ${resp1.json()['nonTaxableTotal']}  ${nonTaxableTotal}
    # Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    # Should Be Equal As Strings  ${resp1.json()['netTaxAmount']}  ${tax}
    # Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${netTotal}
    # Should Be Equal As Strings  ${resp1.json()['netRate']}  ${totalamt}
    # Should Be Equal As Strings  ${resp1.json()['amountTotal']}  ${netTotal}
    # Should Be Equal As Strings  ${resp1.json()['amountDue']}  ${totalamt}


    ${resp}=  Generate Link For Invoice  ${invoice_uid1}   ${primaryMobileNo}    ${email}    ${boolean[1]}    ${boolean[1]}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Service payment modes    ${pid}    ${sid2}    ${purpose[0]}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    # Should Be Equal As Strings  ${resp.json()[0]['isJaldeeBank']}    ${bool[1]}
    Set Suite Variable    ${proid}  ${resp.json()[0]['profileId']}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_uid1}  ${nonTaxableTotal}   ${purpose[0]}    ${source}  ${pid}   ${finance_payment_modes[8]}  ${bool[0]}   ${sid2}   ${pcid18}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${bal_netTotal}=    Evaluate  ${netTotal}-${nonTaxableTotal}


    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid2}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    Should Be Equal As Strings  ${resp1.json()['netTaxAmount']}  ${tax}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${netTotal}
    Should Be Equal As Strings  ${resp1.json()['netRate']}  ${totalamt}
    Should Be Equal As Strings  ${resp1.json()['amountTotal']}  ${netTotal}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}  ${totalamt}

JD-TC-CreateInvoice-18

    [Documentation]  try to pay full amount for that invoice.

    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Service payment modes    ${pid}    ${sid2}    ${purpose[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${tax1}=  Evaluate  ${taxableTotal}*${gstpercentage[3]}
    ${tax}=   Evaluate  ${tax1}/100
    ${tax}=  Convert To Number  ${tax}  2

    ${totalamt}=  Evaluate  ${netTotal}+${tax}
    ${totalamt}=  twodigitfloat  ${totalamt}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_uid1}  ${nonTaxableTotal}   ${purpose[1]}    ${source}  ${pid}   ${finance_payment_modes[8]}  ${bool[0]}   ${sid2}   ${pcid18}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME42}  ${PASSWORD}
    Log  ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${bal_netTotal}=    Evaluate  ${netTotal}-${nonTaxableTotal}

    ${resp1}=  Get Invoice By Id  ${invoice_uid1}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${account_id1}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${category_id2}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${name1}
    Should Be Equal As Strings  ${resp1.json()['invoiceDate']}  ${invoiceDate}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${sid2}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  ${quantity}
    Should Be Equal As Strings  ${resp1.json()['taxableTotal']}  ${taxableTotal}
    Should Be Equal As Strings  ${resp1.json()['netTaxAmount']}  ${tax}
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${netTotal}
    Should Be Equal As Strings  ${resp1.json()['netRate']}  ${totalamt}
    Should Be Equal As Strings  ${resp1.json()['amountTotal']}  ${netTotal}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}  0

JD-TC-CreateInvoice-19

    [Documentation]  Taking appointment from consumer side and the consumer doing the prepayment - check invoice(auto-invoice generation flag is on) (Tax Disabled)


    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    # clear_appt_schedule   ${HLPUSERNAME2}

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
    Set Test Variable  ${accountId3}  ${resp.json()['accountId']}   



    ${resp}=  Get Business Profile
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}
    Set Suite Variable  ${accountId3}  ${resp.json()['id']}

    ${resp}=  Get Appointment Schedules
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Appointment Settings
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableAppt']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['enableToday']}   ${bool[1]}

    ${P1SERVICE2}=    FakerLibrary.word
    Set Suite Variable   ${P1SERVICE2}
    ${desc}=   FakerLibrary.sentence
    ${maxBookingsAllowed}=   Random Int   min=2   max=5
    ${min_pre1}=   Random Int   min=40   max=50
    ${Tot}=   Random Int   min=100   max=300
    ${min_pre1}=   Random Int   min=40   max=50
    ${Tot}=   Random Int   min=100   max=300
    ${min_pre1}=  Convert To Number  ${min_pre1}  1
    Set Test Variable   ${min_pre1}
    # ${pre_float}=  twodigitfloat  ${min_pre}
    ${Tot11}=  Convert To Number  ${Tot}  1 
    Set Suite Variable   ${Tot3}   ${Tot11}
    ${resp}=  Create Service  ${P1SERVICE2}  ${desc}  ${service_duration1}  ${bool[1]}  ${Tot3}  ${bool[1]}    minPrePaymentAmount=${min_pre1}   maxBookingsAllowed=${maxBookingsAllowed}   prePaymentType=${advancepaymenttype[1]}   automaticInvoiceGeneration=${bool[1]}
    # ${resp}=  Create Service  ${P1SERVICE2}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${min_pre1}  ${Tot3}  ${bool[1]}  ${bool[0]}    maxBookingsAllowed=${maxBookingsAllowed}    prePaymentType=${advancepaymenttype[1]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${p1_sid2}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid2}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    ${resp}=  Create Sample Location  
    Set Suite Variable    ${loc_id1}    ${resp}  

    ${resp}=   Get Location ById  ${loc_id1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${tz}  ${resp.json()['timezone']}

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
    ${resp}=  Create Appointment Schedule  ${schedule_name}  ${recurringtype[1]}  ${list}  ${DAY1}  ${DAY2}  ${EMPTY}  ${sTime1}  ${eTime1}  ${parallel}    ${parallel}  ${loc_id1}  ${duration}  ${bool1}  ${p1_sid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${sch_id}  ${resp.json()}

    ${resp}=  Get Appointment Schedule ById  ${sch_id}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  id=${sch_id}   name=${schedule_name}  apptState=${Qstate[0]}

    ${resp}=  Get Appointment Slots By Date Schedule  ${sch_id}  ${DAY1}  ${p1_sid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  scheduleName=${schedule_name}  scheduleId=${sch_id}
    Set Test Variable   ${slot1}   ${resp.json()['availableSlots'][0]['time']}


    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}  
    Log  ${resp.json()}



    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200


    ${firstName}=  FakerLibrary.name
    Set Test Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Test Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo2}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo2}
    ${email}=    FakerLibrary.Email
    Set Test Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo2}    ${accountId3}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo2}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${tokens}  ${resp.json()['token']}

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo2}     ${accountId3}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo2}    ${accountId3}  ${tokens} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid5}    ${resp.json()['providerConsumer']}




    ${DAY1}=  db.get_date_by_timezone  ${tz}
    ${resp}=    Get All Schedule Slots By Date Location and Service  ${accountId3}  ${DAY1}  ${loc_id1}  ${p1_sid2}
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
    ${j1}=  Random Int  max=${num_slots-1}
    Set Test Variable   ${slot1}   ${slots[${j1}]}

    ${apptfor1}=  Create Dictionary  id=${self}   apptTime=${slot1}
    ${apptfor}=   Create List  ${apptfor1}

    ${cnote}=   FakerLibrary.name
    ${resp}=   Take Appointment For Provider   ${accountId3}  ${p1_sid2}  ${sch_id}  ${DAY1}  ${cnote}   ${apptfor}    location=${loc_id1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
          
    ${apptid1}=  Get Dictionary Values  ${resp.json()}
    Set Suite Variable  ${apptid1}  ${apptid1[0]} 


    ${resp}=   Get consumer Appointment By Id   ${accountId3}  ${apptid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    Verify Response    ${resp}     uid=${apptid1}   appmtDate=${DAY1}   appmtTime=${slot1}
    Should Be Equal As Strings  ${resp.json()['service']['id']}   ${p1_sid2}
    Should Be Equal As Strings  ${resp.json()['schedule']['id']}   ${sch_id}
    Should Be Equal As Strings  ${resp.json()['apptStatus']}  ${apptStatus[0]}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['firstName']}   ${firstName}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['lastName']}   ${lastName}
    Should Be Equal As Strings  ${resp.json()['appmtFor'][0]['apptTime']}   ${slot1}
    Should Be Equal As Strings  ${resp.json()['location']['id']}   ${loc_id1}

    ${resp}=  Make payment Consumer Mock  ${accountId3}  ${min_pre1}  ${purpose[0]}  ${apptid1}  ${p1_sid2}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}

    #sleep   01s

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Appointment By Id   ${apptid1}
    Log   ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
 
    ${resp}=   Get Service By Id  ${p1_sid2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    ${balamount_appt}=  Evaluate  ${Tot3}-${min_pre1}
    ${balamount_appt}=  Convert To Number  ${balamount_appt}  2
    Set Suite Variable   ${balamount_appt}   

    #sleep   01s
    ${resp}=  Get Booking Invoices  ${apptid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${invoice_apptonline_uid}  ${resp.json()[0]['invoiceUid']}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceId']}  ${p1_sid2}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['serviceName']}  ${P1SERVICE2}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['price']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['netRate']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['serviceList'][0]['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp.json()[0]['amountPaid']}  ${min_pre1}
    Should Be Equal As Strings  ${resp.json()[0]['amountDue']}  ${balamount_appt}
    Should Be Equal As Strings  ${resp.json()[0]['amountTotal']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['defaultCurrencyAmount']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['netTotal']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['netRate']}  ${Tot3}
    Should Be Equal As Strings  ${resp.json()[0]['taxableTotal']}  0.0
    Should Be Equal As Strings  ${resp.json()[0]['taxPercentage']}  0.0
    Should Be Equal As Strings  ${resp.json()[0]['netTaxAmount']}  0.0
    Should Be Equal As Strings  ${resp.json()[0]['ynwUuid']}  ${apptid1}
    Should Be Equal As Strings  ${resp.json()[0]['billPaymentStatus']}  ${paymentStatus[1]}


JD-TC-CreateInvoice-20

    [Documentation]  Consumer doing full payment then - check invoice(auto-invoice generation flag is on) (Tax Disabled)


    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo2}    ${accountId3}  ${tokens} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200



    # ${resp}=  Make payment Consumer Mock  ${accountId3}  ${balamount_appt}  ${purpose[1]}  ${invoice_apptonline_uid}  ${p1_sid2}  ${bool[0]}   ${bool[1]}  ${None}
    # Log  ${resp.json()}
    # # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable   ${mer}   ${resp.json()['merchantId']}  
    # Set Suite Variable   ${payref}   ${resp.json()['paymentRefId']}

    ${source}=   FakerLibrary.word

    ${resp1}=  Invoice pay via link  ${invoice_apptonline_uid}  ${balamount_appt}   ${purpose[6]}    ${source}  ${accountId3}   ${finance_payment_modes[8]}  ${bool[0]}   ${p1_sid2}   ${cid5}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200


    #sleep   01s

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}   name-eq=${Booking} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable   ${categ_id}   ${resp.json()[0]['id']}




   ${resp1}=  Get Invoice By Id  ${invoice_apptonline_uid}
    Log  ${resp1.content}
    Should Be Equal As Strings  ${resp1.status_code}  200
    Should Be Equal As Strings  ${resp1.json()['accountId']}  ${accountId3}
    Should Be Equal As Strings  ${resp1.json()['invoiceCategoryId']}  ${categ_id}
    Should Be Equal As Strings  ${resp1.json()['categoryName']}  ${Booking}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['serviceId']}  ${p1_sid2}
    Should Be Equal As Strings  ${resp1.json()['serviceList'][0]['quantity']}  1.0
    Should Be Equal As Strings  ${resp1.json()['netTotal']}  ${Tot3}
    Should Be Equal As Strings  ${resp1.json()['netRate']}  ${Tot3}
    Should Be Equal As Strings  ${resp1.json()['amountTotal']}  ${Tot3}
    Should Be Equal As Strings  ${resp1.json()['amountDue']}  0
    Should Be Equal As Strings  ${resp1.json()['billPaymentStatus']}  ${paymentStatus[2]}

JD-TC-CreateInvoice-UH4

    [Documentation]  Try to disable finance after taking waitlist from consumer side and the consumer doing the prepayment -  (Tax enabled)

   
    ${firstname}  ${lastname}  ${PUSERPH2}  ${LoginId}=  Provider Signup
    Set Suite Variable  ${PUSERPH2}


    # ------------- Get general details and settings of the provider and update all needed settings
    
    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${pid1}  ${resp.json()['id']}
    Set Test Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${DAY}=  db.get_date_by_timezone  ${tz}
    Set Test Variable  ${DAY}  

    ${resp}=   Get License UsageInfo 
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Verify Response  ${resp}  onlineCheckIns=${bool[1]}

    ${resp}=  Enable Waitlist
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${resp1}=   Run Keyword If  ${resp.json()['onlinePresence']}==${bool[0]}   Set jaldeeIntegration Settings    ${boolean[1]}  ${boolean[1]}  ${EMPTY}
    Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.content}
    Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['walkinConsumerBecomesJdCons']}   ${bool[1]}

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END
    
    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

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
    Set Test Variable  ${accountId1}  ${resp.json()['accountId']}    
    

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${GST_num}  ${pan_num}=   db.Generate_gst_number   ${Container_id}
    ${resp}=  Update Tax Percentage  ${gstpercentage[3]}  ${GST_num} 
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    
    ${resp}=  Enable Tax
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200
    
    ${p1_lid}=  Create Sample Location
    ${resp}=  Get Locations
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${p1_lid}  ${resp.json()[0]['id']} 

    ${min_pre}=   Random Int   min=40   max=50
    ${Tot}=   Random Int   min=100   max=300
    ${min_pre}=  Convert To Number  ${min_pre}  1
    Set Test Variable   ${min_pre}
    # ${pre_float}=  twodigitfloat  ${min_pre}
    ${Tot1}=  Convert To Number  ${Tot}  1 
    Set Test Variable   ${Tot}   ${Tot1}

    ${P1SERVICE1}=    FakerLibrary.word
    Set Test Variable   ${P1SERVICE1}
    ${desc}=   FakerLibrary.sentence
    ${maxBookingsAllowed}=   Random Int   min=2   max=5
    ${resp}=  Create Service  ${P1SERVICE1}  ${desc}  ${service_duration1}  ${bool[1]}  ${Tot}  ${bool[1]}    minPrePaymentAmount=${min_pre}   automaticInvoiceGeneration=${bool[1]}

    # ${resp}=  Create Service  ${P1SERVICE1}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${min_pre}  ${Tot}  ${bool[1]}  ${bool[1]}    maxBookingsAllowed=${maxBookingsAllowed}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${p1_sid1}  ${resp.json()}

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid1}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid1}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}


    ${P1SERVICE2}=    FakerLibrary.word
    Set Test Variable   ${P1SERVICE2} 
    ${desc}=   FakerLibrary.sentence
    ${resp}=  Create Service  ${P1SERVICE2}  ${desc}  ${service_duration1}  ${bool[0]}  ${Tot}  ${bool[0]}    automaticInvoiceGeneration=${bool[1]}
    # ${resp}=  Create Service  ${P1SERVICE2}  ${desc}   ${service_duration1}  ${status[0]}    ${btype}    ${bool[1]}  ${notifytype[2]}  ${EMPTY}  ${Tot}  ${bool[0]}  ${bool[1]}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${p1_sid2}  ${resp.json()}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    ${serviceprice}=   Random Int  min=100  max=500
    ${serviceprice}=  Convert To Number  ${serviceprice}  1
    ${serviceList1}=  Create Dictionary  serviceId=${p1_sid2}   quantity=${quantity}   price=${serviceprice} 

    # ${resp}=  Auto Invoice Generation For Service   ${p1_sid2}    ${toggle[0]}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Service By Id  ${p1_sid2}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['automaticInvoiceGeneration']}    ${bool[1]}

    ${queue1}=    FakerLibrary.word
    ${capacity}=  FakerLibrary.Numerify  %%
    ${sTime}=  add_timezone_time  ${tz}  2  00  
    ${eTime}=  add_timezone_time  ${tz}  2  15  
    ${parallel}=   Random Int  min=1   max=1
    ${resp}=  Create Queue  ${queue1}  ${recurringtype[1]}  ${list}  ${DAY}  ${EMPTY}  ${EMPTY}  ${sTime}  ${eTime}  ${parallel}  ${capacity}  ${p1_lid}  ${p1_sid1}  ${p1_sid2}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${p1_qid}  ${resp.json()}

    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=  ProviderLogout
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200



    ${firstName}=  FakerLibrary.name
    Set Test Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Test Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Test Variable    ${primaryMobileNo}
    ${email}=    FakerLibrary.Email
    Set Test Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${accountId1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${jsessionynw_value}=   Get Cookie from Header  ${resp}

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}  JSESSIONYNW=${jsessionynw_value} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable  ${token}  ${resp.json()['token']}

    ${resp}=    Consumer Logout  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email}    ${primaryMobileNo}     ${accountId1}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId1}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Test Variable    ${cid1}    ${resp.json()['providerConsumer']}


    ${msg}=  Fakerlibrary.word
    Append To File  ${EXECDIR}/data/TDD_Logs/msgslog.txt  ${SUITE NAME} - ${TEST NAME} - ${msg}${\n}
    ${resp}=  Add To Waitlist Consumers  ${cid1}   ${pid1}  ${p1_qid}  ${DAY}  ${p1_sid1}  ${msg}  ${bool[0]}  ${self}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200 
    ${wid}=  Get Dictionary Values  ${resp.json()}
    Set Test Variable  ${cwid}  ${wid[0]} 
    
    ${tax1}=  Evaluate  ${Tot}*${gstpercentage[3]}
    ${tax}=   Evaluate  ${tax1}/100
    ${totalamt}=  Evaluate  ${Tot}+${tax}
    ${totalamt}=  Convert To Number  ${totalamt}  2
    ${totalamt}=  Evaluate  "%.2f" % ${totalamt}
    # ${totalamt}=  twodigitfloat  ${totalamt}
    ${balamount}=  Evaluate  ${totalamt}-${min_pre}
    ${balamount}=  Convert To Number  ${balamount}  2


    ${resp}=  Get consumer Waitlist By Id  ${cwid}  ${pid1}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Verify Response  ${resp}  paymentStatus=${paymentStatus[0]}   waitlistStatus=${wl_status[3]}


    #sleep   02s

    ${resp}=  Make payment Consumer Mock  ${pid1}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${None}
    Log  ${resp.json()}
    # ${resp}=  Make payment Consumer Mock  ${pid}  ${min_pre}  ${purpose[0]}  ${cwid}  ${p1_sid1}  ${bool[0]}   ${bool[1]}  ${cid1}
    # Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp}=  Make payment Consumer Mock  ${min_pre}  ${bool[1]}  ${cwid}  ${pid}  ${purpose[0]}  ${cid1}
    # Log  ${resp.json()}
    # Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable   ${mer}   ${resp.json()['merchantId']}  
    Set Test Variable   ${payref}   ${resp.json()['paymentRefId']}

    ${resp}=  Encrypted Provider Login  ${PUSERPH2}  ${PASSWORD}
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    # ${resp1}=  Get consumer Waitlist Bill Details   ${cwid}
    # Log  ${resp1.content}
    # Should Be Equal As Strings  ${resp1.status_code}  200

    #sleep   02s

    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[1]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[1]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  422
        Should Be Equal As Strings  ${resp1.json()}   ${CANNOT_DISABLE_FINANCE}
    END

    ${resp}=  Get jp finance settings    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[1]}
 
    






JD-TC-CreateInvoice-24

    [Documentation]  Try to disable finance where only one service is there with zero amount(we can disable finance manager in this case)

    ${firstname}  ${lastname}  ${PUSERPH5}  ${LoginId}=  Provider Signup
    Set Suite Variable  ${PUSERPH5}   


    
    # ------------- Get general details and settings of the provider and update all needed settings
    
    ${resp}=  Get Business Profile
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${pid1}  ${resp.json()['id']}
    Set Test Variable  ${tz}  ${resp.json()['baseLocation']['timezone']}

    ${resp}=   Get License UsageInfo 
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    
    ${resp}=  Get Waitlist Settings
    Log  ${resp.content}
    Verify Response  ${resp}  onlineCheckIns=${bool[1]}

    ${resp}=  Enable Waitlist
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    ${resp1}=   Run Keyword If  ${resp.json()['onlinePresence']}==${bool[0]}   Set jaldeeIntegration Settings    ${boolean[1]}  ${boolean[1]}  ${EMPTY}
    Run Keyword If   '${resp1}' != '${None}'  Log  ${resp1.content}
    Run Keyword If   '${resp1}' != '${None}'  Should Be Equal As Strings  ${resp1.status_code}  200

    ${resp}=   Get jaldeeIntegration Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['onlinePresence']}   ${bool[1]}
    Should Be Equal As Strings  ${resp.json()['walkinConsumerBecomesJdCons']}   ${bool[1]}

    ${resp}=  Get Account Settings
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END
    
    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF  ${resp.json()['onlinePayment']}==${bool[0]}   
        ${resp}=   Enable Disable Online Payment   ${toggle[0]}
        Should Be Equal As Strings  ${resp.status_code}  200
    END

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
    Set Test Variable  ${accountId1}  ${resp.json()['accountId']}    
    

    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    

    
    ${p1_lid}=  Create Sample Location
    ${resp}=  Get Locations
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Test Variable  ${p1_lid}  ${resp.json()[0]['id']} 

    ${resp}=   Get Service
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=   Get Category With Filter  categoryType-eq=${categoryType[3]}  
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200




    ${resp}=  Get jp finance settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    
    IF  ${resp.json()['enableJaldeeFinance']}==${bool[1]}
        ${resp1}=    Enable Disable Jaldee Finance   ${toggle[1]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
      
    END

    ${resp}=  Get jp finance settings    
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.json()['enableJaldeeFinance']}  ${bool[0]}
 
