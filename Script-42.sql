/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Сергей Панченко
 * Дата:
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь
SELECT CASE WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            WHEN city != 'Санкт-Петербург' THEN 'ЛенОбл'
            END AS region,
      CASE WHEN days_exposition < 31 THEN 'до месяца' 
            WHEN days_exposition < 91 THEN 'до трех месяцев'
            WHEN days_exposition < 181 THEN 'до полугода'
            WHEN days_exposition > 180 THEN 'более полугода'
            WHEN days_exposition IS NULL THEN 'объявление открыто'
            END AS days,
       COUNT(ea.id) AS count_id,     
       ROUND(AVG(last_price::real/total_area::real)) AS avg_price_m2,
       ROUND(AVG(total_area::integer), 2) AS avg_total_area,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS median_rooms,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS median_balcony,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS median_floor
FROM (WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
     SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
    SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)) AS ef
LEFT JOIN real_estate.advertisement AS ea ON ef.id = ea.id
LEFT JOIN real_estate.city AS ec ON ec.city_id = ef.city_id
LEFT JOIN real_estate.TYPE AS et ON et.type_id = ef.type_id
WHERE TYPE = 'город' 
GROUP BY  region, days
ORDER BY avg_price_m2 DESC




-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- Напишите ваш запрос здесь
WITH fm AS (
SELECT COUNT(first_day_exposition) AS count_first_day_exposition, 
        EXTRACT(MONTH FROM first_day_exposition) AS  first_month,
        ROUND(AVG(last_price::REAL / total_area::real)) AS avg_price,
        ROUND(AVG(total_area::integer), 2) AS avg_total_area
FROM (WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
     SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)) AS ef
LEFT JOIN real_estate.advertisement AS ea ON ef.id = ea.id
LEFT JOIN real_estate.type AS et ON et.type_id = ef.type_id
WHERE et.TYPE = 'город'
GROUP BY first_month
ORDER BY first_month
),
lm AS (
SELECT COUNT(first_day_exposition + days_exposition::integer) AS count_last_day_exposition,
       EXTRACT(MONTH FROM first_day_exposition + (days_exposition::integer*'1 day'::INTERVAL)) AS last_month,
       ROUND(AVG(last_price::REAL / total_area::real)) AS avg_price_closed,
       ROUND(AVG(total_area::integer), 2) AS avg_total_area_closed
FROM (WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
     SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)) AS ef    
LEFT JOIN real_estate.advertisement AS ea ON ef.id = ea.id
WHERE days_exposition IS NOT NULL
GROUP BY last_month
ORDER BY last_month
)
SELECT first_month,
       count_first_day_exposition,
       row_number() OVER(ORDER BY count_first_day_exposition DESC) AS row_num,
       avg_price,
       avg_total_area,
       last_month,
       avg_price_closed,
       avg_total_area_closed,
       count_last_day_exposition,
       row_number() OVER(ORDER BY count_last_day_exposition DESC) AS row_num_1
FROM  fm
LEFT JOIN lm ON lm.last_month = fm.first_month

-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь
SELECT city,
       COUNT(ea.id) AS count_advertisement,
       ROUND(AVG(last_price::real/total_area::real)) AS avg_price_m2,
       ROUND(AVG(total_area::integer), 2) AS avg_total_area,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS median_rooms,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS median_balcony,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS median_floor,
       COUNT(first_day_exposition + days_exposition::integer)::REAL /COUNT(first_day_exposition)::REAL AS share_last_advertisement, -- доля снятых объявлений
       ROUND(AVG(days_exposition)) AS avg_days_exposition -- средняя продолжительность публикации объявления
FROM (WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
     SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
    SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id)) AS ef
LEFT JOIN real_estate.advertisement AS ea ON ef.id = ea.id
LEFT JOIN real_estate.city AS ec ON ec.city_id = ef.city_id
WHERE  city != 'Санкт-Петербург'
GROUP BY  city
ORDER BY count_advertisement DESC
LIMIT 15