*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           OperatingSystem
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${username}=    Get User Name
   
    Open the robot order website
    ${orders}=    GET CSV file from the user
    
    FOR    ${row}    IN    @{orders}
        
        Close the annoying modal
        Fill the form    ${row}
         Preview the robot
         Wait Until Keyword Succeeds     10x     2s    Submit The Order
         

         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
       
    END
    Create a Zip File of the Receipts
    [Teardown]  Log out and close the browser
    Display the success dialog  USER_NAME=${username}
    


Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    credentials
#     # Note: In real robots, you should not print secrets to the log.
#     # This is just for demonstration purposes. :)
    Log    ${secret}[username]
    Log    ${secret}[password]
    
*** Variables ***
${RadioButton}      id=id-body-
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       0.5s
${receipt_dir}       ${OUTPUT_DIR}${/}receipts
*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


# Get orders
#     Download    url=https://robotsparebinindustries.com/orders.csv        target_file=orders.csv    overwrite=True
#     ${table}=   Read table from CSV    path=orders.csv 
#     [Return]    ${table}

Close the annoying modal
    
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
Fill the form
    [Arguments]     ${mrow} 
    
    Select From List By Value       xpath=//*[@id="head"]     ${mrow}[Head]
    Set Local Variable    ${body}       ${mrow}[Body]
    Set Local Variable      ${input_body}       body
    Select Radio Button             ${input_body}           ${body}
    Input Text            xpath=//input[@placeholder='Enter the part number for the legs']   ${mrow}[Legs]
    Input Text            xpath=//*[@id="address"]   ${mrow}[Address]



 Preview the robot
    Click Button     xpath://*[@id="preview"]
    Wait Until Element Is Visible     xpath://*[@id="robot-preview-image"]
    
Submit the order check 
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Submit the order 
  
          

Submit the order 
    Click Button       xpath://*[@id="order"]
    Wait Until Element Is Visible                 xpath://*[@id="receipt"]

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Set Local Variable    ${file_path}    ${OUTPUT_DIR}${/}RobotOrder_${order_number}.png
    Screenshot        xpath://*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}RobotOrder_${order_number}.png
    [Return]    ${file_path}
 


 Store the receipt as a PDF file
     [Arguments]    ${order_number}
    ${receipt_html} =  Get Element Attribute     id:receipt    outerHTML 
    Set Local Variable    ${file_path}    ${receipt_dir}${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${file_path}
    [Return]    ${file_path}
Embed the robot screenshot to the receipt PDF file 
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${image_files} =    Create List    ${screenshot}:align=center
    Add Files To PDF    ${image_files}    ${pdf}    append=True
    Close Pdf    ${pdf}

Create receipt PDF with robot preview image
    [Arguments]    ${order_number}    ${screenshot}
    ${pdf} =    Store the receipt as a PDF file    ${order_number}
    Embed the robot screenshot to the receipt PDF file     ${screenshot}    ${pdf}



Go to order another robot
    Click Button     xpath://*[@id="order-another"]




Create a Zip File of the Receipts
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Log out and close the browser

    Close Browser


Get User Name
    Add heading    User Full Name
    Add text input          YourName    label=Please Enter Your Full Name     placeholder=eg. John Rayn

   ${result}=              Run dialog
    [Return]                ${result.YourName}

Display the success dialog
    [Arguments]   ${USER_NAME}
    Add icon      Success
    Add heading   Your orders have been processed successfully 
    Add text      Dear ${USER_NAME} - all orders have been processed successfully. Thank You!
    Run dialog    title=Success




GET CSV file from the user
     Add heading    
    ...    heading=Upload CSV File
    ...    size=Large 
    Add file input
    ...    label=Please Upload the CSV file with order data
    ...    name=fileupload
    ...    file_type=CSV files (*.csv)
    ...    destination=${CURDIR}${/}output
    ${response}=    Run dialog
    Set Global Variable   ${CSV_FILE}      ${response.fileupload}[0]
    ${table}=   Read table from CSV    path=${CSV_FILE}   dialect=excel    header=True 
    [Return]    ${table}


  


