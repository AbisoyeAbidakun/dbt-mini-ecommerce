#  DBT Setup
1. Setup venv and activate venv
2. Install Requirements
3. Install extensions :Add to GIT Ignore, YAML, Better Jinja

**DBT-for-bigquery-set-up**
1. Set up dbt via command line: from https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup#local-oauth-gcloud-setup
2. gcloud cli ..
2. Authenticate Big-Query - Run this line:
3.
For Mac or Linux
```
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/bigquery,\
https://www.googleapis.com/auth/drive.readonly,\
https://www.googleapis.com/auth/iam.test

```
For Windows:
```
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/iam.test
```


**CREATING A NEW DBT PROJECT**
1. Get into a new project
2. Run: "dbt init" to create a project : input a name
name: your-project-name
chose database: [1] BigQuery
chose authentication: [1] oauth
enter GCP Project name OR ID:
enter dataset name
thread: 60
select;  US

### NOTE: Always ensure you are inside the folder that has your dbt virtual environment and that your virtual environment is activated

3. Run:
```
dbt debug --config-dir
```

4. open the profiles.yaml :  >> copy the dev profiles and create a productions profile : change the schema

create new branch by clicking on main: switch to the branch >> stage the changes and commit

**Install dbt power user extension:**
1. Search for dbt power user: install
2. Run " command shift p "
3. In the tab tha shows up search for user settings.json : open it and copy the below into the json file:
Add this to the file
```

    // Associated the right file types with the right VSCode extensions
    "files.associations": {
        "*.sql": "jinja-sql"
    },

    // CRUCIAL - you need to change this to terminal.integrated.env.[osx|windows|linux] depending on your system
    // and point it to the folder where your profiles directory is stored!
    "terminal.integrated.env.osx": {
        "DBT_PROFILES_DIR": "fill-this-with-the-path-to-the-folder-containing-your-profiles.yaml-file-on-your-local-file",
		"BIGQUERY_PROJECT": "fill-this-with-your-gcp-pproject-name"
   },

```
Above
 a. if you are on a mac you can add this  ```~/.dbt``` as ```DBT_PROFILES_DIR```
 b. add ```GCP-PROJECT-ID``` as  BIGQUERY_PROJECT NAME
 c. In the  ```terminal.integrated.env.osx``` tag replace "osx" with  either ```windows or linux``` depending on your system's OS

4. run "dbt clean && dbt deps"
5. Restart the vs code or run "command shift p" >> select reload window >> choose the correct python interpreter
6. check the models folder to see if the models have the dbt icon (it works successfully if it does)

**NOTE ADD thelook_ecommerce (ECOMMERCE)  DATA FROM BIGQUERY PUBLIC DATASET**

**Dbt Project Architecture: Source >> Staging >> Intermediate >> Final Table (Fact or Dimensions Table or View)**
(Staging : Usually layer of transformation)
1. Create a staging folder   inside the models folder
2. Inside the staging folder : add a src_ecommerce.yml file and file it up with all the souce description as below:
```
version: 2

sources:
  - name: thelook_ecommerce
    database: bigquery-public-data
    tables:
      - name: inventory_items
      - name: order_items
      - name: orders
      - name: products
      - name: users

```

3. Inside the same root that has the dbt_project.yml create a packages.yml and fill it up as below:

```
packages:
  - package: dbt-labs/dbt_utils
    version: 1.0.0

  - package: calogica/dbt_expectations
    version: [">=0.8.0", "<0.9.0"]

  - package: dbt-labs/codegen
    version: 0.9.0
```
4. Run: ``` dbt deps ```
5. Before running the next command ensure that the bigquery-public-data.thelook_ecommerce has been pulled into your bigquery project: do this on the bigquery

6. To generate the query for the staging orders table,  Run:
	```
	dbt run-operation  --profiles-dir /Users/abidakunabisoye/.dbt generate_base_model --args '{"source_name": "thelook_ecommerce", "table_name": "orders"}'

	```
	or

	```
	 dbt run-operation generate_base_model --args '{"source_name": "thelook_ecommerce", "table_name": "orders"}'

	```
7. Create a stg_ecommerce_orders.sql
8. After running the above query a query is generated : copy the query generated and paste into the stg_ecommerce_orders.sql
9. Run:
``` dbt run ``` or ``` dbt run -s stg_ecommerce_orders ```
10. Generate the yml file for the stg_ecommerce_orders model: run
  ``` dbt run-operation  generate_model_yaml  --args '{"model_names": ["stg_ecommerce_orders"]}'
  ```
  or
  ```
  dbt run-operation  --profiles-dir /Users/path-to-profiles.yaml-file/.dbt generate_model_yaml  --args '{"model_names": ["stg_ecommerce_orders"]}'
  ```
11. Crteated a stg_ecommerce_orders.yml file and paste in the result of the previous command
12. Update the table as shown below
```
## Testing, documentation, Referencing and configuration
version: 2

models:
  - name: stg_ecommerce_orders
    description: " Table describing and detailing every order on per row basis "
    columns:
      - name: order_id
        description: "The order Id of the order"
        tests:
          - not_null
          - unique

      - name: user_id
        description: "User Id who placed the order "
        tests:
          - not_null

      - name: created_at
        description: "When the order was placed"
        tests:
          - not_null

      - name: returned_at
        description: "When the order was returned"
        tests:
          - not_null:
              where: "status = 'Returned'"

      - name: shipped_at
        description: "When the order was shipped"
        tests:
          - not_null:
              where: " delivered_at IS NOT NULL OR status = 'Shipped'"

      - name: delivered_at
        description: "When the order was delivered"
        tests:
          - not_null:
              where: " returned_at IS NOT NULL OR status = 'Complete'"

      - name: status
        description: "Status of the order"
        tests:
          - accepted_values:
               name: expected_order_status
               values:
                - Processing
                - Cancelled
                - shipped
                - Complete
                - Returned

      - name: num_of_item
        description: "Number of items in the order"
        tests:
          - not_null:

```
13. Run : ``` dbt test -s stg_ecommerce_orders ```
14. Running ``` dbt run and dbt test```   == ``` dbt build ```
15. To add descriptions to bigquery: add this under materialisation in the dbt_project.yml file:
```
+materialized: table
+persist_docs:
  relation: true
  columns: true
```
16. Run dbt run --full-refresh
17. Create a intermediate folder in the models folder
18. Add two files into the marts folders: int_order_items_products.sql or int_ecommerce.yml
Fill up the two folders up...
19. Create a marts folder in the models folder
20. Add two files into the marts folders: orders.sql or orders.yml
21.

## Advanced Testing
-- Freshness:
**Setting Severity Level for Test**
1.  Open the dbt_projects.yml file
2.  Add severity level of error for the project to severity warn
```
tests:
  learning:
     +severity: warn # this means all test in the project has a default levle of warn
```
3. Comment out the women on the dbt accepted value test in stg_ecommerce_products
4.  Run
```dbt clean && dbt deps
```
5. dbt test -s  stg_ecommerce_products

**Macros for Testing**
1. Add this to the stg_ecommerce_products.yml file
```
      - name: cost
        description: "How much the product cost the business to purchase"
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0

      - name: retail_price
        description: "How much the product retails for on the online store"
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
          - dbt_utils.expression_is_true:
              name: retail_price_not_leading_to_loss
              expression: ">=cost"
```
(Naming the test is useful for debugging what test failed)
2. Run the Test
``` dbt test -s  stg_ecommerce_products
```

**Writing Custom Test**
1. Create file in the tests folder called test_orders_match_order_items_details.sql

## Advanced Data Modelling
1. Create a folder named documents in the models
2. add the folder called doc_order_status.md in
3. paste into it
```
{% docs status %}

The status of the order. Can be one of:
- Processing
- Cancelled
- Shipped
- Complete
- Returned

{% enddocs %}
```
4. Inside the orders.yml and stg_ecommerce_orders.ym; file input  the following:
```
   - name: order_status
        description: "{{ doc('status') }}"
```
5. Run : dbt run -s stg_ecommerce_orders
6. Go to the bigquery table to see the data description

**Add Seed**
1. Describe slowly changing data types:
2. Create a distribution_center.csv file inside the seed folder
3. Paste into it
```
id,name,latitude,longitude
11,Miami FL,25.7617,-80.191788
12,Denver CO,39.7392,-104.9903
```
4. create a seed.yml file inside the seed folder
5. Paste into it:
```
version: 2

seeds:
  - name: seed_distribution_centers_new
    description: "An example of using a CSV file to load data into your warehouse"
    tests:
      - dbt_expectations.expect_table_row_count_to_equal:
          value: 2

    # Column names, descriptions, and tests can all be done as normal
    columns:
      - name: id
        tests:
          - not_null
          - unique
      - name: name
        description: "Distribution center name"
      - name: latitude
      - name: longitude

    # If you want to enforce datatypes, you can do so here
    # Otherwise, BigQuery will do it for you!
    config:
      column_types:
        id: INTEGER
        name: STRING
        latitude: FLOAT
        longitude: FLOAT
```
6. Run : dbt seed
7. Check the bigquery table for the seed materialisation

**Adding Snapshot**
Explain what snap_shot means:
Open this: "https://docs.getdbt.com/docs/build/snapshots"
1. Create a file in the snapshot folder names snapshot_distribution_centre.sql
2. Paste into it:
```
{% snapshot snapshot_distribution_centre %}

{{
    config(
      target_schema='dbt_test',
      unique_key='id',
      strategy='check',
      check_cols=['name', 'latitude', 'longitude']
    )
}}

SELECT * FROM {{ source('thelook_ecommerce', 'distribution_centers') }}

{% endsnapshot %}
```
3. Explain the target_schema concept
4. Add to the src_ecommerce.yml file
```
  - name: distribution_centers
```
4. Run dbt snapshot
5. Update the seed file with the remaining csv row
6. Run dbt seed
7. Run dbt snapshot
8. Run dbt
9. Discribe the changes in the valid to and updated columns

**Explain Models**
### Add Ephemerals
1. Create an sql file called int_initial_order_created in the intermediate folder
```
{{
	config(materialized='ephemeral')
}}


SELECT
	user_id,
	MIN(created_at) AS first_order_created_at

FROM {{ ref('stg_ecommerce_orders') }}
GROUP BY 1

```
2. Add ` -&user_id `to the int_ecommerce.yml to the user_id
3. Add the this below in the int_ecommerce.yml file
```
  - name: int_initial_order_created
    columns:
      - *user_id
      # This would keep the name & tests defined in the anchor, but overwrite the description
```
4. Add this to the orders.sql file
```
-- a good way to demonstrate how to use an ephemeral materialisation
	TIMESTAMP_DIFF(od.created_at, user_data.first_order_created_at, DAY) AS days_since_first_order

```
and join with

```
LEFT JOIN {{ ref('int_initial_order_created') }} AS user_data
	ON od.user_id = user_data.user_id
```
9. run the orders.sql model

