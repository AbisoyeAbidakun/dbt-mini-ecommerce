WITH source AS (
SELECT 
 *
FROM {{ source('thelook_ecommerce', 'inventory_items') }}

)

SELECT 
 * 
FROM source