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
Resource          /ebs/TDD/ProviderConsumerKeywords.robot
Resource          /ebs/TDD/ConsumerKeywords.robot
Variables         /ebs/TDD/varfiles/providers.py
Variables         /ebs/TDD/varfiles/consumerlist.py
Variables         /ebs/TDD/varfiles/hl_providers.py
Resource          /ebs/TDD/SuperAdminKeywords.robot

*** Variables ***
${invalidNum}        1245
${invalidEma}        asd122
${invalidstring}     _ad$.sa_
${invalidItem}     sprx-3250dr0-800

*** Test Cases ***

JD-TC-Create Sales Order Invoice-1
    [Documentation]   Create a sales Order with Valid Details then Genarate sales order invoice.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    # sleep  01s
    ${resp}=  Get Account Settings
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200

    IF  ${resp.json()['enableInventory']}==${bool[0]}
        ${resp1}=  Enable Disable Inventory  ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200

        ${resp}=  Get Account Settings
        Log  ${resp.json()}
        Should Be Equal As Strings  ${resp.status_code}  200
        Should Be Equal As Strings  ${resp.json()['enableInventory']}  ${bool[1]}
    END

    IF  ${resp.json()['enableSalesOrder']}==${bool[0]}
        ${resp1}=  Enable/Disable SalesOrder  ${toggle[0]}
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200

        ${resp}=  Get Account Settings
        Log  ${resp.json()}
        Should Be Equal As Strings  ${resp.status_code}  200
        Should Be Equal As Strings  ${resp.json()['enableSalesOrder']}  ${bool[1]}
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

    ${resp}=  Get Store Type By Filter     
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  SuperAdmin Login  ${SUSERNAME}  ${SPASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
# --------------------- Create Store Type from sa side -------------------------------
    ${TypeName}=    FakerLibrary.name
    Set Suite Variable  ${TypeName}
    # sleep  03s

    ${resp}=  Create Store Type   ${TypeName}    ${storeNature[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable    ${St_Id}    ${resp.json()}

    # ${resp}=  Get Store Type By EncId   ${St_Id}    
    # Log   ${resp.content}
    # Should Be Equal As Strings    ${resp.status_code}    200

# --------------------- ---------------------------------------------------------------

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${accountId}=  get_acc_id  ${HLPUSERNAME29}
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

# ------------------------ Create Store ----------------------------------------------------------

    ${DAY1}=  db.get_date_by_timezone  ${tz}
    Set Suite Variable  ${DAY1} 

    ${Name}=    FakerLibrary.last name
    ${PhoneNumber}=  Evaluate  ${PUSERNAME}+100187748
    Set Test Variable  ${email_id}  ${Name}${PhoneNumber}.${test_mail}
    ${email}=  Create List  ${email_id}

    ${resp}=  Create Store   ${Name}  ${St_Id}    ${locId1}  ${email}     ${PhoneNumber}  ${countryCodes[0]}   onlineOrder=${boolean[1]}    walkinOrder=${boolean[1]}   partnerOrder=${boolean[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${store_id}  ${resp.json()}

# ---------------------------------------------------------------------------------------------------

# --------------------------- Create SalesOrder Inventory Catalog-InvMgr False ------------------------------------

    ${resp}=  Create SalesOrder Inventory Catalog-InvMgr False   ${store_id}   ${Name}  ${boolean[0]}   onlineSelfOrder=${boolean[1]}  walkInOrder=${boolean[1]}  storePickup=${boolean[1]}  courierService=${boolean[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${SO_Cata_Encid}  ${resp.json()}
# --------------------------------------------------------------------------------------------------------------
# ----------------------------------------  Create Item ---------------------------------------------------

    ${displayName}=     FakerLibrary.name
    ${displayName1}=     FakerLibrary.name
    ${resp}=    Create Item Inventory  ${displayName}    
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId1}  ${resp.json()}

    ${resp}=    Create Item Inventory  ${displayName1}    
    Log   ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${itemEncId2}  ${resp.json()}

    ${itemdata}=   FakerLibrary.words    	nb=4

    ${displayName1}=   FakerLibrary.user name    
    ${price1}=  Evaluate    random.uniform(50.0,300) 
    ${itemName1}=   Set Variable     ${itemdata[0]} 
    ${itemCode1}=   Set Variable     ${itemdata[1]}
    ${resp}=  Create Sample Item   ${displayName1}   ${itemName1}  ${itemCode1}  ${price1}  ${bool[0]}     
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${item_id1}  ${resp.json()}
# -------------------------------------------------------------------------------------------------------------------
# -------------------------------- Create SalesOrder Catalog Item-invMgmt False -----------------------------------

    ${price}=    Random Int  min=2   max=40
    ${invCatItem}=     Create Dictionary       encId=${itemEncId2}
    ${Item_details}=  Create Dictionary        spItem=${invCatItem}    price=${price}   


    ${resp}=  Create SalesOrder Catalog Item-invMgmt False      ${SO_Cata_Encid}     ${itemEncId1}     ${price}     ${Item_details}    
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Set Suite Variable  ${SO_itemEncIds}  ${resp.json()[0]}
    Set Suite Variable  ${SO_itemEncIds2}  ${resp.json()[1]}

# -------------------------------- Add a provider Consumer -----------------------------------

    ${firstName}=  FakerLibrary.name
    Set Suite Variable    ${firstName}
    ${lastName}=  FakerLibrary.last_name
    Set Suite Variable    ${lastName}
    ${primaryMobileNo}    Generate random string    10    123456789
    ${primaryMobileNo}    Convert To Integer  ${primaryMobileNo}
    Set Suite Variable    ${primaryMobileNo}
    # ${email}=    FakerLibrary.Email
    # Set Suite Variable    ${email}

    ${resp}=    Send Otp For Login    ${primaryMobileNo}    ${accountId}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Verify Otp For Login   ${primaryMobileNo}   ${OtpPurpose['Authentication']}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${token}  ${resp.json()['token']}

    ${resp}=    Consumer Logout 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    ProviderConsumer SignUp    ${firstName}  ${lastName}  ${email_id}    ${primaryMobileNo}     ${accountId}
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}   200    
   
    ${resp}=    ProviderConsumer Login with token   ${primaryMobileNo}    ${accountId}  ${token} 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable    ${cid}    ${resp.json()['providerConsumer']}

    ${resp}=    Consumer Logout 
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

# --------------------------------------------------------------------------------------------------------

# ----------------------------- Provider take a Sales Order ------------------------------------------------

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${quantity}=    Random Int  min=2   max=5

    ${Cg_encid}=  Create Dictionary   encId=${SO_Cata_Encid}   
    ${SO_Cata_Encid_List}=  Create List       ${Cg_encid}
    Set Suite Variable  ${SO_Cata_Encid_List}

    ${store}=  Create Dictionary   encId=${store_id}  
    ${items}=  Create Dictionary   catItemEncId=${SO_itemEncIds}    quantity=${quantity}   catItemBatchEncId=${SO_itemEncIds}

    ${resp}=    Create Sales Order    ${SO_Cata_Encid_List}   ${cid}   ${cid}   ${originFrom[5]}    ${items}    store=${store}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Set Suite Variable  ${SO_Uid}  ${resp.json()}

    ${netTotal}=  Evaluate  ${price}*${quantity}
    ${netTotal}=  Convert To Number  ${netTotal}   1


    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    # Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    # Should Be Equal As Strings    ${resp.json()['accountId']}                                       ${accountId}
    # Should Be Equal As Strings    ${resp.json()['location']['id']}                                  ${locId1}
    # Should Be Equal As Strings    ${resp.json()['store']['name']}                                   ${Name}
    # Should Be Equal As Strings    ${resp.json()['store']['encId']}                                  ${store_id}

    # Should Be Equal As Strings    ${resp.json()['catalog'][0]['name']}                                 ${Name}
    # Should Be Equal As Strings    ${resp.json()['catalog'][0]['encId']}                                ${SO_Cata_Encid}
    # Should Be Equal As Strings    ${resp.json()['catalog'][0]['invMgmt']}                              ${bool[0]}

    # Should Be Equal As Strings    ${resp.json()['providerConsumer']['id']}                          ${cid}
    # Should Be Equal As Strings    ${resp.json()['orderFor']['id']}                                  ${cid}
    # Should Be Equal As Strings    ${resp.json()['orderFor']['name']}                                ${firstName} ${lastName}

    # Should Be Equal As Strings    ${resp.json()['orderType']}                                       ${bookingChannel[0]}
    # Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[0]}
    # Should Be Equal As Strings    ${resp.json()['deliveryType']}                                    ${deliveryType[0]}
    # Should Be Equal As Strings    ${resp.json()['deliveryStatus']}                                  ${deliveryStatus[0]}
    # Should Be Equal As Strings    ${resp.json()['originFrom']}                                      ${originFrom[5]}

    # Should Be Equal As Strings    ${resp.json()['orderNum']}                                        1
    # Should Be Equal As Strings    ${resp.json()['orderRef']}                                        1
    # Should Be Equal As Strings    ${resp.json()['deliveryDate']}                                    ${DAY1}

    # Should Be Equal As Strings    ${resp.json()['contactInfo']['phone']['number']}                  ${primaryMobileNo}
    # Should Be Equal As Strings    ${resp.json()['contactInfo']['email']}                            ${email_id}

    # Should Be Equal As Strings    ${resp.json()['itemCount']}                                       1
    # Should Be Equal As Strings    ${resp.json()['netTotal']}                                        ${netTotal}
    # Should Be Equal As Strings    ${resp.json()['taxTotal']}                                        0.0
    # Should Be Equal As Strings    ${resp.json()['discountTotal']}                                   0.0
    # Should Be Equal As Strings    ${resp.json()['jaldeeCouponTotal']}                               0.0
    # Should Be Equal As Strings    ${resp.json()['providerCouponTotal']}                             0.0
    # Should Be Equal As Strings    ${resp.json()['netRate']}                                         ${netTotal}
    # Should Be Equal As Strings    ${resp.json()['cgstTotal']}                                       0.0

    # Should Be Equal As Strings    ${resp.json()['sgstTotal']}                                       0.0
    # Should Be Equal As Strings    ${resp.json()['gst']}                                       0.0
    # Should Be Equal As Strings    ${resp.json()['cessTotal']}                                       0.0
# -----------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------- Update SalesOrder Status --------------------------------------------------------

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[1]}
# ------------------------------------------------------------------------------------------------------------------------------------

# ------------------------------------------------Create Sales Order Invoice----------------------------------------------

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

JD-TC-Create Sales Order Invoice-2
    [Documentation]    Genarate sales order invoice multiple times.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

JD-TC-Create Sales Order Invoice-3
    [Documentation]    order assign to a user then user Genarate sales order invoice.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Get Business Profile
    Log  ${resp.json()}
    Should Be Equal As Strings  ${resp.status_code}  200
    Set Suite Variable  ${acc_id}   ${resp.json()['id']}
    Set Suite Variable  ${sub_domain_id}  ${resp.json()['serviceSubSector']['id']}

    ${resp}=  Get Waitlist Settings
    Log  ${resp.json()}
    Should Be Equal As Strings    ${resp.status_code}    200
    IF  ${resp.json()['filterByDept']}==${bool[0]}
        ${resp}=  Enable Disable Department  ${toggle[0]}
        Log  ${resp.json()}
        Should Be Equal As Strings  ${resp.status_code}  200

    END

    ${resp}=  Get Departments
    Log  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200
    IF   '${resp.content}' == '${emptylist}'
        ${dep_name1}=  FakerLibrary.bs
        ${dep_code1}=   Random Int  min=100   max=999
        ${dep_desc1}=   FakerLibrary.word  
        ${resp1}=  Create Department  ${dep_name1}  ${dep_code1}  ${dep_desc1} 
        Log  ${resp1.content}
        Should Be Equal As Strings  ${resp1.status_code}  200
        Set Suite Variable  ${dep_id}  ${resp1.json()}
    ELSE
        Set Suite Variable  ${dep_id}  ${resp.json()['departments'][0]['departmentId']}
    END

    ${PUSERNAME_U1}  ${u_id} =  Create and Configure Sample User   deptId=${dep_id}

    ${resp}=    Assign User For Sales Order    ${SO_Uid}     ${u_id}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Provider Logout
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME_U1}  ${PASSWORD}
    Should Be Equal As Strings  ${resp.status_code}   200


    # ${us_id2}=  Create Sample User    
    # Set Suite Variable    ${us_id2}

    # ${resp}=  Get User By Id  ${us_id2}
    # Log  ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable  ${f_name1}  ${resp.json()['firstName']}
    # Set Suite Variable  ${l_name1}  ${resp.json()['lastName']}

    # Set Suite Variable  ${PUSERNAME_U1}  ${resp.json()['mobileNo']}



    # ${resp}=  SendProviderResetMail   ${PUSERNAME_U1}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # @{resp}=  ResetProviderPassword  ${PUSERNAME_U1}  ${PASSWORD}  2
    # Should Be Equal As Strings  ${resp[0].status_code}  200
    # Should Be Equal As Strings  ${resp[1].status_code}  200

    # ${resp}=  Encrypted Provider Login  ${PUSERNAME_U1}  ${PASSWORD}
    # Log   ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200


JD-TC-Create Sales Order Invoice-UH1
    [Documentation]    Genarate  invoice with invalid Sales order Uid.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Create Sales Order Invoice    ${invalidNum}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422
    Should Be Equal As Strings    ${resp.json()}   ${INVALID_ORDER_ID}

JD-TC-Create Sales Order Invoice-UH2
    [Documentation]    Genarate  invoice with not assigned user.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${PUSERNAME_U2}  ${us_id3} =  Create and Configure Sample User   deptId=${dep_id} 

    # ${us_id3}=  Create Sample User    
    # Set Suite Variable    ${us_id3}

    # ${resp}=  Get User By Id  ${us_id3}
    # Log  ${resp.content}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # Set Suite Variable  ${f_name1}  ${resp.json()['firstName']}
    # Set Suite Variable  ${l_name1}  ${resp.json()['lastName']}

    # Set Suite Variable  ${PUSERNAME_U2}  ${resp.json()['mobileNo']}

    # ${resp}=  SendProviderResetMail   ${PUSERNAME_U2}
    # Should Be Equal As Strings  ${resp.status_code}  200
    # @{resp}=  ResetProviderPassword  ${PUSERNAME_U2}  ${PASSWORD}  2
    # Should Be Equal As Strings  ${resp[0].status_code}  200
    # Should Be Equal As Strings  ${resp[1].status_code}  200

    ${resp}=  Encrypted Provider Login  ${PUSERNAME_U2}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  200

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422

JD-TC-Create Sales Order Invoice-UH3
    [Documentation]    Genarate invoice with another provider.

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME19}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   422

JD-TC-Create Sales Order Invoice-4
    [Documentation]    Update sales order status as ORDER_CANCELED then Genarate invoice .

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

# --------------------------------------------- Update SalesOrder Status --------------------------------------------------------

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[3]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[3]}
# ------------------------------------------------------------------------------------------------------------------------------------

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

JD-TC-Create Sales Order Invoice-5
    [Documentation]    Update sales order status as ORDER_DISCARDED then Genarate invoice .

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

# --------------------------------------------- Update SalesOrder Status --------------------------------------------------------

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[0]}
# ------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------- Update SalesOrder Status --------------------------------------------------------

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[4]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[4]}
# ------------------------------------------------------------------------------------------------------------------------------------

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

JD-TC-Create Sales Order Invoice-6
    [Documentation]    Update sales order status as ORDER_COMPLETED then Genarate invoice .

    ${resp}=  Encrypted Provider Login  ${HLPUSERNAME29}  ${PASSWORD}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

# --------------------------------------------- Update SalesOrder Status --------------------------------------------------------

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[0]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[0]}

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[1]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[1]}

    ${resp}=    Update SalesOrder Status    ${SO_Uid}     ${orderStatus[2]}
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200

    ${resp}=    Get Sales Order    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200
    Should Be Equal As Strings    ${resp.json()['uid']}                                           ${SO_Uid}
    Should Be Equal As Strings    ${resp.json()['orderStatus']}                                     ${orderStatus[2]}
# ------------------------------------------------------------------------------------------------------------------------------------

    ${resp}=    Create Sales Order Invoice    ${SO_Uid}   
    Log   ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}   200