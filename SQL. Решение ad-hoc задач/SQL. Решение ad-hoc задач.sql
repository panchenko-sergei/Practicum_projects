/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Панченко Сергей
 * Дата: 14.11.2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
WITH        -- для начала необходимо получить информацию об общем количестве игроков и количестве платящих игроков, для этого используем CTE                     
      count_us AS(
SELECT COUNT(id) AS count_users,  -- выводим общее количество игроков
       (SELECT COUNT(id)           -- используя подзапрос в SELECT находим тут же количество платящих игроков у которых payer = 1
       payer
FROM fantasy.users
GROUP BY payer
HAVING payer = 1) AS count_users_payer -- количество платящих игроков
FROM fantasy.users         -- вся информация берется из таблицы users 
)                          -- по итогу получилось общее количество игроков 22 214, количество платящих 3 929
SELECT count_users,        -- теперь используем основной запрос и выводим общие данные из предыдущего запроса
       count_users_payer,
       count_users_payer::real/count_users::real AS share_users_payer -- а так же в основном запросе подсчитываем долю платящих клиентов, делим платящих на общих, получилось 17%
FROM count_us  

ИТОГ: всего 17% игроков от общего количества платят

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
WITH  count_us AS(       -- Так же как и в предыдущей задаче используем CTE
SELECT race,
        COUNT(id) AS count_users_payer_race --находим количество платящих игроков
FROM fantasy.users AS fu
LEFT  JOIN fantasy.race AS fr ON fr.race_id = fu.race_id -- присоединяем к таблице users таблицу race по ключу race_id
WHERE payer = 1
GROUP BY race     -- производим группировку  платящих игроков по рассе 
),
   count_us1 AS (
SELECT race,
        COUNT(id) AS count_users --находим количество  игроков
FROM fantasy.users AS fu
LEFT  JOIN fantasy.race AS fr ON fr.race_id = fu.race_id
GROUP BY race
)
SELECT  cu.race,  -- в основном запросе выводим информацию об общем количестве игроков, о количестве платящих игроков по рассам
        count_users_payer_race,
        count_users,
        count_users_payer_race::real/count_users::REAL AS share_users_payer_race -- считаем долю платящих от общего количества  игроков в разрезе рас
FROM count_us AS cu
LEFT JOIN count_us1 AS cu1 ON cu1.race = cu.race
ORDER BY share_users_payer_race DESC -- для получения наилучшей визуализации и топа фильтруем долю платящих игроков в разрезе расс по убыванию

ИТОГ: доля платящих игроков от общего количества игроков в разрезе рас примерно одинаковая 17-19%
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT 
       COUNT(amount) AS count_amount, -- количество покупок
       SUM(amount) AS sum_amount, -- общая сумма покупок
       MIN(amount) AS min, -- максимальная сумма покупки
       MAX(amount) AS max, -- минимальная сумма покупки
       SUM(amount)/COUNT(amount) AS avg_sum_amount, -- средняя сумма одной покупки
       COUNT(amount)/2 AS count_median,-- центральное значение медианы
       STDDEV(amount) AS stand_dev, -- стандартное отклонение
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median -- медиана
FROM fantasy.events
WHERE amount > 0
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT COUNT(transaction_id) FILTER (WHERE amount = 0), -- количество нулевых покупок
       COUNT(transaction_id), -- общее количество покупок
       COUNT(transaction_id) FILTER (WHERE amount = 0)::real/COUNT(transaction_id)::REAL AS share -- доля нулевых покупок от общего количества покупок
FROM fantasy.events 
-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
SELECT 
     CASE
      	WHEN payer = 1     -- указываем в таблице платящих и не платящих игроков
      	THEN 'платящий'
      	WHEN payer = 0
      	THEN 'не платящий'
      END AS pay,
      COUNT(DISTINCT(fe.id)) AS count_user, -- рассчитываем количество которые совершали покупки, данные из таблицы events
      SUM(amount) AS sum_am, -- рассчитываем сумму всех покупок
      SUM(amount)::NUMERIC / COUNT(DISTINCT fu.id) AS avg_transaction, -- средняя сумма покупок
      COUNT(transaction_id)::NUMERIC / COUNT(DISTINCT fu.id) AS avg_count -- среднее количество покупок
FROM fantasy.users AS fu
JOIN fantasy.events  AS fe ON fe.id = fu.id  -- к таблице users присоединяем таблицу events с данными опокупках
WHERE amount > 0
GROUP BY pay


Платящие игроки по странам
SELECT location,
       COUNT(id)
FROM fantasy.users AS fu
LEFT JOIN fantasy.country AS fcu ON fcu.loc_id = fu.loc_id  -- присоединяем к таблице users таблицу со странами country
GROUP BY location, payer 
HAVING payer = 1 -- выбираем платящих игроков
ORDER BY COUNT(id) DESC
-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH count_1 AS(
       SELECT game_items,
       COUNT(transaction_id) AS count_gi,
       COUNT(DISTINCT(id)) AS count_user,
       (SELECT COUNT(transaction_id)
       FROM fantasy.events) AS ccc,
       (SELECT COUNT(DISTINCT(id))
       FROM fantasy.events) AS ccc2
FROM fantasy.events AS fe
LEFT JOIN fantasy.items AS fi ON fi.item_code= fe.item_code -- присоединяем к покупкам таблицу с названием эпических предметов
WHERE amount > 0
GROUP BY game_items 
ORDER BY COUNT(transaction_id) DESC -- фильтруем по количеству покупок в порядке убывания, чтобы сразу визуализировать топ
)
SELECT game_items,
       count_gi, -- количество продаж по предметам
       count_user, -- количество купивших хотя бы раз предмет
       count_gi::real/ccc::REAL AS share_transaction, -- доля количества продаж от общего количества
       count_user::real /ccc2::real AS share_user -- доля игроков от общего количества покупателей
FROM count_1 AS c_1
GROUP BY game_items, count_gi, ccc, count_user,ccc2
ORDER BY count_gi DESC

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH count_1 AS(
SELECT COUNT(id) AS count_users_race, -- общее количество игроков по расам
        race
FROM fantasy.users AS fu
LEFT  JOIN fantasy.race AS fr ON fr.race_id = fu.race_id
GROUP BY race       
ORDER BY count_users_race DESC
),
count_2 AS(
SELECT COUNT(DISTINCT(fe.id)) AS count_users_payer_race, -- количество платящих игроков по расам, взял платящих именно из таблицы events, а не users как в прошлый раз
       race
FROM fantasy.users AS fu
LEFT  JOIN fantasy.race AS fr ON fr.race_id = fu.race_id 
LEFT  JOIN fantasy.events AS fe ON fe.id = fu.id
WHERE payer = 1
GROUP BY race     
ORDER BY  count_users_payer_race DESC
),
count_3 AS (
SELECT COUNT(DISTINCT fe.id) AS count_event, -- количество игроков, которые совершают внутриигровые покупки
       COUNT(transaction_id)::real/COUNT(DISTINCT fe.id)::real AS avg_count_user, -- среднее количество покупок на одного игрока
       SUM(amount)::real/COUNT(transaction_id)::real AS avg_amount_user, -- средняя стоимость одной покупки на одного игрока
       SUM(amount)::real/COUNT(DISTINCT fe.id)::real AS avg_sum_user, -- средняя суммарная стоимость всех покупок на одного игрока
       COUNT(DISTINCT fe.id)::real/COUNT(fu.id)::REAL AS share_pay_users, -- доля покупателей от общего количества игроков
       race
FROM fantasy.events AS fe
LEFT JOIN fantasy.users AS fu ON fu.id = fe.id 
LEFT JOIN fantasy.race AS fr ON fr.race_id = fu.race_id 
WHERE amount > 0
GROUP BY race
)
SELECT c2.race,
       c1.count_users_race,
       c2.count_users_payer_race,
       count_event,
       count_users_payer_race::real/count_event::real AS share_pay,-- доля платящих игроков от общего количества игроков совершивших покупки
       avg_count_user,
       avg_amount_user,
       avg_sum_user,
       share_pay_users
 FROM count_2 AS c2
 LEFT JOIN count_3 AS c3 ON c3.race = c2.race
 LEFT JOIN count_1 AS c1 ON c1.race = c2.race
 ORDER BY count_users_race DESC

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
 WITH
    info_event AS(
SELECT fu.id,
      tech_nickname,  -- выводим общую информацию по каждому игроку
      fr.race, --посмтрим за какие расы играют топ покупателей в игре
      COUNT(transaction_id) AS transaction_count, -- рассчитываем количество покупок для каждого игрока
      MAX(date::DATE) AS last_transaction_date, -- находим дату последней покупки
      CURRENT_DATE - MAX(date::DATE) AS days_since_last_transaction, -- вычисляем количество дней, которое прошло с момента последней покупки
      CASE
      	WHEN payer = 1     -- указываем в таблице платящих и не платящих игроков
      	THEN 'платящий'
      	WHEN payer = 0
      	THEN 'не платящий'
      END AS pay,
      NTILE(3) OVER(ORDER BY COUNT(transaction_id) DESC) AS rang  -- ранжируем результат на 3 группы в зависимости от количества покупок
FROM fantasy.users AS fu
JOIN fantasy.events  AS fe ON fe.id = fu.id  -- к таблице users присоединяем таблицу events с данными опокупках
JOIN fantasy.race AS fr ON fr.race_id = fu.race_id -- присоединяем таблицу с расой
WHERE amount > 0  -- убираем нулевые покупки по стоимости
GROUP BY fu.id, tech_nickname, fr.race
HAVING COUNT(transaction_id) > 25 -- выводим только тех игроков, которые совершили более 25 покупок
ORDER BY transaction_count DESC, days_since_last_transaction ASC
)
SELECT *,
      CASE                          -- каждой группе в зависимости от ранга присваиваем название
      WHEN rang = 1
      THEN 'высокая частота'
      WHEN rang = 2
      THEN 'умеренная частота'
      WHEN rang = 3
      THEN 'низкая частота'
      END AS rang_name
FROM info_event 




