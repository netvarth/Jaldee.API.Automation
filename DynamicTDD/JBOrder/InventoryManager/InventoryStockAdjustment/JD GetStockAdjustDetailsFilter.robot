*** Settings ***
Suite Teardown    Delete All Sessions
Test Teardown     Delete All Sessions
Force Tags        STORE 
Library           Collections
Library           String
Library           json
Library           DateTime
Library           requests
Library           FakerLibrary
Library           /ebs/TDD/db.py
Resource          /ebs/TDD/ProviderKeywords.robot
Resource          /ebs/TDD/Keywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_musers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot

*** Variables ***
${invalidNum}        1245
${invalidEma}        asd122
${invalidstring}     _ad$.sa_


*** Test Cases ***

JD-TC-Get Item Stock adjust Details Filter-1

    [Documentation]  Get Item Stock adjust Details Filter  using account.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Store Type By Filter     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${TypeName}=    FakerLibrary.name
    Set Suite Variable  ${TypeName}

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}
    sleep  02s
    ${TypeName1}=    FakerLibrary.name
    Set Suite Variable  ${TypeName1}

    ${resp}=  Create Store Type   ${TypeName1}    ${storeNature[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id1}    ${resp.json()}
    sleep  02s
    ${TypeName2}=    FakerLibrary.name
    Set Suite Variable  ${TypeName2}

    ${resp}=  Create Store Type   ${TypeName2}    ${storeNature[2]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id2}    ${resp.json()}

    ${resp}=  Get Store Type By EncId   ${St_Id}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=  get_acc_id  ${HLMUSERNAME6}
    Set Suite Variable    ${accountId} 

    ${resp}=  Provide Get Store Type By EncId     ${St_Id}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${locId1}=  Create Sample Location
        ${resp}=   Get Location ById  ${locId1}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Suite Variable  ${tz}  ${resp.json()['bSchedule']['timespec'][0]['timezone']}
        Set Suite Variable  ${place}  ${resp.json()[0]['place']}
    ELSE
        Set Suite Variable  ${locId1}  ${resp.json()[0]['id']}
        Set Suite Variable  ${tz}  ${resp.json()[0]['bSchedule']['timespec'][0]['timezone']}
        Set Suite Variable  ${place}  ${resp.json()[0]['place']}
    END

    ${Name}=    FakerLibrary.last name
    Set Suite Variable  ${Name}

    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Name}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}

    ${resp}=    Get Store ByEncId   ${store_id}
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${id_of_store}  ${resp.json()['id']}

    ${resp}=  Create Inventory Catalog   ${Name}  ${store_id}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${inventory_catalog_encid}  ${resp.json()}

    ${resp}=  Get Inventory Catalog By EncId   ${inventory_catalog_encid}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${id_of_inventory_catalog}  ${resp.json()['id']}

    ${displayName}=     FakerLibrary.name

    ${resp}=    Create Item Inventory  ${displayName}    
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId1}  ${resp.json()}

    ${categoryName}=    FakerLibrary.name
    Set Suite Variable  ${categoryName}

    ${resp}=  Create Item Category   ${categoryName}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable    ${Ca_Id}    ${resp.json()}

    ${resp}=    Create Item Inventory  ${categoryName}   categoryCode=${Ca_Id} 
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncIds}  ${resp.json()}


    ${resp}=   Create Inventory Catalog Item  ${inventory_catalog_encid}   ${itemEncId1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${inventory_catalog_item_encid}  ${resp.json()[0]}

    ${resp}=   Get Inventory Catalog item By EncId  ${inventory_catalog_item_encid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 
    Set Suite Variable  ${id_of_inventory_catalog_item}  ${resp.json()['id']}

    ${remarks}=    FakerLibrary.name
    Set Suite Variable  ${remarks}

    ${resp}=  Create Item Remarks   ${remarks}  ${transactionTypeEnum[1]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${remarks_encid1}  ${resp.json()}

    ${resp}=  Get Item Remark   ${remarks_encid1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${id}  ${resp.json()['id']}

    ${quantity}=   Random Int  min=5  max=10
    ${quantity}=  Convert To Number  ${quantity}  1
    Set Suite Variable  ${quantity}  
    ${data}=  Create Dictionary   invCatalogId=${inventory_catalog_encid}   invCatalogItemId=${inventory_catalog_item_encid}    qty=${quantity}    
    Set Suite Variable  ${data}  
    ${resp}=  Create Stock Adjustment   ${locId1}  ${store_id}   ${inventory_catalog_encid}   ${remarks_encid1}      ${data} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${uid}  ${resp.json()}

    ${resp}=  Get Stock Adjustment By Id  ${uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${id_of_stockadjust}  ${resp.json()['id']}

    ${resp}=  Get Item Stock adjust Details Filter   account-eq=${accountId}     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity}

JD-TC-Get Item Stock adjust Details Filter-2

    [Documentation]  Get Item Stock adjust Details Filter  using invCatalogId.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Stock adjust Details Filter   invCatalogId-eq=${inventory_catalog_encid}       
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity}


JD-TC-Get Item Stock adjust Details Filter-3

    [Documentation]  Get Item Stock adjust Details Filter  using invCatalogItemId.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogItemId-eq=${inventory_catalog_item_encid}       
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity}


JD-TC-Get Item Stock adjust Details Filter-4

    [Documentation]   Get Item Stock adjust Details Filter  using quantity.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    

    ${resp}=  Get Item Stock adjust Details Filter   qty-eq=${quantity}     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity}



JD-TC-Get Item Stock adjust Details Filter-5

    [Documentation]  Get Item Stock adjust Details Filter  using stockAdjust.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Stock adjust Details Filter    stockAdjust-eq=${id_of_stockadjust}     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity}

JD-TC-Get Item Stock adjust Details Filter-6

    [Documentation]  Update Item Stock adjust Details Filter  using stockAdjust then Get Item Stock adjust Details Filter.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${quantity1}=   Random Int  min=5  max=10
    ${quantity1}=  Convert To Number  ${quantity1}  1
    Set Suite Variable  ${quantity1}
    ${data1}=  Create Dictionary   invCatalogId=${inventory_catalog_encid}   invCatalogItemId=${inventory_catalog_item_encid}    qty=${quantity1}    

    ${quantity2}=   Random Int  min=10  max=15
    ${quantity2}=  Convert To Number  ${quantity2}  1
    Set Suite Variable  ${quantity2}
    ${data2}=  Create Dictionary   invCatalogId=${inventory_catalog_encid}   invCatalogItemId=${inventory_catalog_item_encid}    qty=${quantity2}   

    ${resp}=  Update Stock Adjustment  ${uid}   ${locId1}  ${store_id}   ${inventory_catalog_encid}   ${remarks_encid1}      ${data}   ${data1}   ${data2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogId-eq=${inventory_catalog_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity2}

    Should Be Equal As Strings    ${resp.json()[1]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[1]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[1]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[1]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[1]['qty']}     ${quantity1}

    Should Be Equal As Strings    ${resp.json()[2]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[2]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[2]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[2]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[2]['qty']}     ${quantity}

JD-TC-Get Item Stock adjust Details Filter-7

    [Documentation]  create Item Stock adjust   then Get Item Stock adjust Details Filter.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name1}=    FakerLibrary.last name
    Set Suite Variable  ${Name1}

    ${resp}=  Create Inventory Catalog   ${Name1}  ${store_id}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${inventory_catalog_encid1}  ${resp.json()}

    ${resp}=   Create Inventory Catalog Item  ${inventory_catalog_encid1}   ${itemEncId1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${inventory_catalog_item_encid1}  ${resp.json()[0]}

    ${quantity3}=   Random Int  min=5  max=10
    ${quantity3}=  Convert To Number  ${quantity3}  1
    Set Suite Variable  ${quantity3}  
    ${data3}=  Create Dictionary   invCatalogId=${inventory_catalog_encid1}   invCatalogItemId=${inventory_catalog_item_encid1}    qty=${quantity3}    
    Set Suite Variable  ${data3}  

    ${resp}=  Create Stock Adjustment   ${locId1}  ${store_id}   ${inventory_catalog_encid1}   ${remarks_encid1}    ${data3} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${uid1}  ${resp.json()}

    ${resp}=  Get Stock Adjustment By Id  ${uid1}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${id_of_stockadjust1}  ${resp.json()['id']}

    ${resp}=  Get Item Stock adjust Details Filter    account-eq=${accountId}            
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['id']}    ${id_of_stockadjust1} 
    Should Be Equal As Strings    ${resp.json()[0]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogId']}    ${inventory_catalog_encid1}     
    Should Be Equal As Strings    ${resp.json()[0]['invCatalogItemId']}   ${inventory_catalog_item_encid1}
    Should Be Equal As Strings    ${resp.json()[0]['qty']}     ${quantity3}

    Should Be Equal As Strings    ${resp.json()[1]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[1]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[1]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[1]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[1]['qty']}     ${quantity2}

    Should Be Equal As Strings    ${resp.json()[2]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[2]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[2]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[2]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[2]['qty']}     ${quantity1}

    Should Be Equal As Strings    ${resp.json()[3]['stockAdjust']['id']}    ${id_of_stockadjust} 
    Should Be Equal As Strings    ${resp.json()[3]['stockAdjust']['invStatus']}    ${InvStatus[0]}
    Should Be Equal As Strings    ${resp.json()[3]['invCatalogId']}    ${inventory_catalog_encid}     
    Should Be Equal As Strings    ${resp.json()[3]['invCatalogItemId']}   ${inventory_catalog_item_encid}
    Should Be Equal As Strings    ${resp.json()[3]['qty']}     ${quantity}

JD-TC-Get Item Stock adjust Details Filter-UH1

    [Documentation]  remove all Stock adjust Details then Get Item Stock adjust Details Filter.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Update Stock Adjustment  ${uid}   ${locId1}  ${store_id}   ${inventory_catalog_encid}   ${remarks_encid1}      
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogId-eq=${inventory_catalog_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()}    [] 

JD-TC-Get Item Stock adjust Details Filter-UH2

    [Documentation]   Get Item Stock adjust Details Filter using invalid invCatalogId.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${quantity1}=   Random Int  min=5  max=10
    ${quantity1}=  Convert To Number  ${quantity1}  1
    ${data1}=  Create Dictionary   invCatalogId=${inventory_catalog_encid}   invCatalogItemId=${inventory_catalog_item_encid}    qty=${quantity1}    

    ${quantity2}=   Random Int  min=10  max=15
    ${quantity2}=  Convert To Number  ${quantity2}  1
    ${data2}=  Create Dictionary   invCatalogId=${inventory_catalog_encid}   invCatalogItemId=${inventory_catalog_item_encid}    qty=${quantity2}   

    ${resp}=  Update Stock Adjustment  ${uid}   ${locId1}  ${store_id}   ${inventory_catalog_encid}   ${remarks_encid1}      ${data}   ${data1}   ${data2}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200 

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogId-eq=${inventory_catalog_item_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()}    [] 

JD-TC-Get Item Stock adjust Details Filter-UH3

    [Documentation]   Get Item Stock adjust Details Filter using invalid stockAdjust.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200



    ${resp}=  Get Item Stock adjust Details Filter    stockAdjust-eq=${inventory_catalog_item_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()}    [] 

JD-TC-Get Item Stock adjust Details Filter-UH4

    [Documentation]   Get Item Stock adjust Details Filter using invalid qty.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Get Item Stock adjust Details Filter    qty-eq=${inventory_catalog_item_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()}    [] 

JD-TC-Get Item Stock adjust Details Filter-UH5

    [Documentation]   Get Item Stock adjust Details Filter using invalid invCatalogItemId.

    ${resp}=  Encrypted Provider Login  ${HLMUSERNAME6}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogItemId-eq=${inventory_catalog_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.json()}    [] 

JD-TC-Get Item Stock adjust Details Filter-UH6

    [Documentation]   Get Item Stock adjust Details Filter without login.

    ${resp}=  Get Item Stock adjust Details Filter    invCatalogItemId-eq=${inventory_catalog_item_encid}           
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    419
    Should Be Equal As Strings   ${resp.json()}   ${SESSION_EXPIRED}




