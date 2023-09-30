with source as (

    select * from {{ source('thelook_ecommerce', 'orders') }}

)


    select
	    --  ids
        order_id,
        user_id,

        -- timestamp
        created_at,
        returned_at,
        shipped_at,
        delivered_at,

		--  other columns
		status,
        num_of_item

    from source
