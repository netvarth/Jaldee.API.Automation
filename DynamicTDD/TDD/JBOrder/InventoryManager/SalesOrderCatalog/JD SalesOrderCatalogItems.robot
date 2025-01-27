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
Variables         /ebs/TDD/varfiles/hl_providers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot

*** Variables ***
${invalidNum}        1245
${invalidEma}        asd122
${invalidstring}     _ad$.sa_
@{spItemSource}      RX       Ayur

*** Test Cases ***

JD-TC-Sales Order Catalog Items-1
    [Documentation]  Test whether the system can successfully create items with all items having invMgmt set to false.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
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
    sleep  02s

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}


    # ${resp}=  Get Store Type By EncId   ${St_Id}    
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # Should Be Equal As Strings    ${resp.json()['name']}    ${TypeName}
    # Should Be Equal As Strings    ${resp.json()['storeNature']}    ${storeNature[0]}
    # Should Be Equal As Strings    ${resp.json()['encId']}    ${St_Id}

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${accountId}=  get_acc_id  ${HLPUSERNAME8}
    Set Suite Variable    ${accountId} 

    ${resp}=  Provider Get Store Type By EncId     ${St_Id}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=    Get Locations
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${locId1}=  Create Sample Location
        ${resp}=   Get Location ById  ${locId1}
        Log  ${resp.content}
        Should Be Equal As Strings  ${resp.status_code}  200
        Set Suite Variable  ${tz}  ${resp.json()['timezone']}
    ELSE
        Set Suite Variable  ${locId1}  ${resp.json()[0]['id']}
        Set Suite Variable  ${tz}  ${resp.json()[0]['timezone']}
    END

    ${Name}=    FakerLibrary.last name
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Suite Variable  ${PhoneNumber} 
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}
    Set Suite Variable  ${email} 

    ${resp}=  Create Store   ${Name}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}

    # ${resp}=  Create SalesOrder Inventory Catalog   ${store_id}   ${Name}  ${boolean[1]}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200
    # Set Suite Variable  ${SO_Cata_Encid}  ${resp.json()}



    ${resp}=  Create Inventory Catalog   ${Name}  ${store_id}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${Inv_cat_id}  ${resp.json()}

    ${resp}=  Get Inventory Catalog By EncId   ${Inv_cat_id}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${displayName}=     FakerLibrary.name

    ${resp}=    Create Item Inventory  ${displayName}     isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId1}  ${resp.json()}

    ${categoryName}=    FakerLibrary.name
    Set Suite Variable  ${categoryName}

    ${resp}=  Create Item Category   ${categoryName}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable    ${Ca_item_Id}    ${resp.json()}

    ${resp}=    Create Item Inventory  ${categoryName}   categoryCode=${Ca_item_Id}   isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncIds}  ${resp.json()}

    ${resp}=   Create Inventory Catalog Item  ${Inv_cat_id}   ${itemEncId1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${Inv_Cata_Item_Encid}  ${resp.json()[0]}

    # ${price}=    Random Int  min=2   max=40

    # ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${itemEncId1}     ${price}         
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200

    # ${resp}=  Create SalesOrder Catalog Item-invMgmt True       ${SO_Cata_Encid}    ${boolean[1]}     ${Inv_Cata_Item_Encid}     ${price}    ${bool[1]}      
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200

    ${Store_note}=  FakerLibrary.name
    ${inv_cat_encid_List}=  Create List  ${Inv_cat_id}
    ${price}=    Random Int  min=2   max=40
    ${price}=  Convert To Number  ${price}    1

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr True   ${store_id}  ${Store_note}  ${boolean[1]}  ${inv_cat_encid_List}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${SO_Cata_Encid}  ${resp.json()}
# ---------------------------------------------------------------------------------------------------------
# ------------------------------Create SalesOrder Catalog Item-invMgmt True-------------------------------

    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid}    ${boolean[1]}     ${Inv_Cata_Item_Encid}     ${price}    ${boolean[0]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    # Set Suite Variable  ${SO_itemEncIds}  ${resp.json()[0]}



JD-TC-Sales Order Catalog Items-2
    [Documentation]  Test whether the system can successfully create items with TaxInclude is True all items having invMgmt set to false .

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${displayName1}=     FakerLibrary.name
    Set Suite Variable  ${displayName1}
    ${resp}=    Create Item Inventory  ${displayName1}    isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId2}  ${resp.json()}

    ${resp}=   Create Inventory Catalog Item  ${Inv_cat_id}   ${itemEncId2}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${Inv_Cata_Item_Encid1}  ${resp.json()[0]}


    ${price}=    Random Int  min=2   max=40



    # ..... Create Tax ......

    ${taxName}=    FakerLibrary.name
    ${taxPercentage}=     Random Int  min=0  max=200
    ${taxPercentage}=           Convert To Number  ${taxPercentage}  1
    ${cgst}=     Evaluate   ${taxPercentage} / 2
    ${sgst}=     Evaluate   ${taxPercentage} / 2
    Set Suite Variable      ${taxName}
    Set Suite Variable      ${taxPercentage}
    Set Suite Variable      ${cgst}
    Set Suite Variable      ${sgst}


    ${resp}=    Create Item Tax  ${taxName}  ${taxtypeenum[0]}  ${taxPercentage}  ${cgst}  ${sgst}  0
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable   ${itemtax_id}  ${resp.json()}




    ${resp}=    Get Item Tax by id  ${itemtax_id}
    Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.json()['taxName']}         ${taxName}
    # Should Be Equal As Strings    ${resp.json()['status']}          ${toggle[0]}
    # Should Be Equal As Strings    ${resp.json()['taxTypeEnum']}     ${taxtypeenum[0]}
    # Should Be Equal As Strings    ${resp.json()['taxCode']}         ${itemtax_id}
    Set Suite Variable              ${itemtax_id1}           ${resp.json()['id']}

    ${tax1}=     Create List  ${itemtax_id1}
    # ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${itemEncId2}     ${price}    TaxInclude=${boolean[1]}    taxes=${tax1}
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200


    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid}    ${boolean[1]}     ${Inv_Cata_Item_Encid1}     ${price}    ${boolean[0]}    TaxInclude=${boolean[1]}    taxes=${tax1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

JD-TC-Sales Order Catalog Items-3
    [Documentation]   create multiple items with same details but price is different.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${price}=    Random Int  min=2   max=40

    ${invCatItem}=     Create Dictionary       encId=${itemEncId2}
    ${catalog_details}=  Create Dictionary        spItem=${invCatItem}    price=${price}    

    # ${items}=    Create List   ${catalog_details}    ${catalog_details}  

    ${price}=    Random Int  min=2   max=40
    ${SP_ITEM_ALREADY_EXIST}=  Format String  ${SP_ITEM_ALREADY_EXIST}  ${displayName1}

    ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${itemEncId2}     ${price}     ${catalog_details}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${SP_ITEM_ALREADY_EXIST}

JD-TC-Sales Order Catalog Items-4
    [Documentation]   create items with SO price is Zero.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${displayName}=     FakerLibrary.name

    ${resp}=    Create Item Inventory  ${displayName}     isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId3}  ${resp.json()}

    ${resp}=   Create Inventory Catalog Item  ${Inv_cat_id}   ${itemEncId3}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${Inv_Cata_Item_Encid3}  ${resp.json()[0]}


    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid}    ${boolean[1]}     ${Inv_Cata_Item_Encid3}     0.0    ${boolean[0]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


 
    # ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${itemEncId3}     0.0     
    # Should Be Equal As Strings    ${resp.status_code}    200


JD-TC-Sales Order Catalog Items-5
    [Documentation]   create items with Empty SP Item.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${price}=    Random Int  min=2   max=40

    ${invCatItem}=     Create Dictionary       encId=${itemEncId2}
    ${catalog_details}=  Create Dictionary        spItem=${invCatItem}    price=${price}    

    # ${items}=    Create List   ${catalog_details}    ${catalog_details}  

    ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${EMPTY}     ${price}     ${catalog_details}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${INVALID_SP_ITEM_ID}

JD-TC-Sales Order Catalog Items-6
    [Documentation]   Test whether the system can successfully create items with all items having invMgmt set to true.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${Name}=    FakerLibrary.first name
    ${resp}=  Create Inventory Catalog   ${Name}  ${store_id}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable  ${inv_cat_encid}  ${resp.json()}



    ${resp}=   Create Inventory Catalog Item  ${inv_cat_encid}   ${itemEncId1}  
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable  ${Inv_Cata_Item_Encid1}  ${resp.json()[0]}

    ${inv_cat_encid1}=  Create List  ${inv_cat_encid}

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr True   ${store_id}  ${Name}  ${boolean[1]}  ${inv_cat_encid1}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Test Variable  ${SO_Cata_Encid1}  ${resp.json()}

    ${price}=    Random Int  min=2   max=40

    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid1}    ${boolean[1]}     ${Inv_Cata_Item_Encid1}     ${price}    ${boolean[1]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200


JD-TC-Sales Order Catalog Items-7
    [Documentation]   create  sales order catalog Item where invMgmt as false.(inventory manager is true)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${price}=    Random Int  min=2   max=40

    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid}    ${boolean[0]}     ${Inv_Cata_Item_Encid}     ${price}    ${boolean[1]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${SP_ITEM_ID_REQUIRED}



JD-TC-Sales Order Catalog Items-8
    [Documentation]   create  sales order catalog Item where invCatItem as invalid string.(inventory manager is true)

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${price}=    Random Int  min=2   max=40

    ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid}    ${boolean[1]}     ${invalidstring}     ${price}    ${boolean[1]}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${INVALID_INVENTORY_CATALOG_ITEM_ID}

JD-TC-Sales Order Catalog Items-9
    [Documentation]    "try to add an inventory item in a non-inventory catalog"

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${displayName}=     FakerLibrary.name

    ${resp}=    Create Item Inventory  ${displayName}     isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId4}  ${resp.json()}


    ${price}=    Random Int  min=2   max=40

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id}   ${displayName}  ${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${SO_Cata_Encid1}  ${resp.json()}


    ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid1}     ${itemEncId4}     ${price}         
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    422
    Should Be Equal As Strings    ${resp.json()}    ${CANT_ADD_INV_ITEM_TO_NONINV_CATALOG}



# JD-TC-Sales Order Catalog Items-10

#     [Documentation]     sales order catalog inventory manager is true but catalog item inventory manager is false with valid details.

#     ${resp}=  Encrypted Provider Login  ${HLPUSERNAME8}  ${PASSWORD}
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200

#     ${Name}=    FakerLibrary.last name
#     ${resp}=  Create Store   ${Name}  ${St_Id1}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${store_id1}  ${resp.json()}

#     ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id1}   ${Name}  ${boolean[1]}
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${SO_Cata_Encid1}  ${resp.json()}

#     ${resp}=  Create Inventory Catalog   ${Name}  ${store_id1}   
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${Inv_cat_id1}  ${resp.json()}

#     ${resp}=  Get Inventory Catalog By EncId   ${Inv_cat_id1}  
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200

#     ${displayName}=     FakerLibrary.name

#     ${resp}=    Create Item Inventory  ${displayName}     isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
#     Log   ${resp.json()}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${itemEncId2}  ${resp.json()}

#     ${categoryName}=    FakerLibrary.name
#     Set Suite Variable  ${categoryName}

#     ${resp}=  Create Item Category   ${categoryName}
#     Log   ${resp.json()}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Test Variable    ${Ca_item_Id1}    ${resp.json()}

#     ${resp}=    Create Item Inventory  ${categoryName}   categoryCode=${Ca_item_Id1}  isBatchApplicable=${boolean[1]}    isInventoryItem=${bool[1]}
#     Log   ${resp.json()}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${itemEncIds}  ${resp.json()}

#     ${resp}=   Create Inventory Catalog Item  ${Inv_cat_id1}   ${itemEncId2}  
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    200
#     Set Suite Variable  ${Inv_Cata_Item_Encid1}  ${resp.json()[0]}


#     ${price}=    Random Int  min=2   max=40

#     ${resp}=  Create SalesOrder Catalog Item-invMgmt True     ${SO_Cata_Encid1}    ${boolean[1]}     ${Inv_Cata_Item_Encid1}    ${price}   ${boolean[1]}    
#     Log   ${resp.content}
#     Should Be Equal As Strings    ${resp.status_code}    422
#     Should Be Equal As Strings    ${resp.json()}    ${PRICE_REQUIRED}
