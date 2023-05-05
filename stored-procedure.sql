-- 1
CREATE TABLE spec
(
    id integer NOT NULL,
    table_name character varying(30) NOT NULL,
    column_name character varying(30) NOT NULL,
    cur_max_value integer NOT NULL
);
--2
INSERT INTO spec VALUES (1, 'spec', 'id', 1);
--3
-- реализация
CREATE OR REPLACE FUNCTION xp (_table_name text, _column_name text) 
RETURNS integer
AS $$
DECLARE
  maxValue integer := 0; -- понадобится для поиска макс. знач. в столбце запрашиваемой таблицы
BEGIN
-- проверяем есть ли в таблице spec запись таблицы и столбца, которые пришли в качестве параметров
  IF 
  	(SELECT COUNT(*)
    FROM spec
	WHERE column_name = _column_name AND table_name = _table_name) > 0
  THEN 
  -- если такая запись нашлась, то увеличиваем макс. значение на 1 и возвращаем это же значение
    UPDATE spec
  	SET cur_max_value = cur_max_value + 1
  	WHERE column_name = _column_name AND table_name = _table_name;
	
  	return cur_max_value from spec
		   WHERE column_name = _column_name AND table_name = _table_name;

  ELSE  
  -- иначе ищем максимальное значение в таблице, название которой пришло параметром, в столбце, 
  -- который так же пришел параметром
    EXECUTE format('SELECT MAX(%s) 
		           FROM %s ', 
				   _column_name, _table_name)
    				INTO maxValue;
					
	-- если приходит null – >  в таблице нет записей -> присваиваем maxValue значение = 1
	-- если же maxValue не null -> инкрементируем maxValue	
	IF maxValue IS null THEN maxValue := 1; ELSE maxValue := maxValue + 1; END IF;
	
	-- далле нам нужно сделать новую запись в таблицу spec. id - это значение,
	-- которое вернула наша функция с параметрами xp('spec', 'id').
	-- следующие два параметра - это название таблицы и столбца, которые пришли при первом вызове функции
	-- записывать строковые данные в PL/pgSQL нужно в одинарных ковычках. Так как мы используем экранирование
	-- ковычки в функции дублируются. Поэтому второй и третий пишем определяем в двойных ковычках явно
	-- в качестве макс. значение передаем уже найденное значение из переменной maxValue
	EXECUTE format('INSERT INTO spec  
					VALUES (%s, ''%s'', ''%s'', %s)', 
				   (SELECT xp('spec', 'id')), _table_name, _column_name, maxValue); 
	-- И возвращаем это макс. значение. Т.е. если в таблице уже была запись в рассматриваемом столбце,
	-- то на выходе из функции будет это значене из столбца, увеличенное на 1. Если не было,
	-- то вернется просто 1.
	RETURN maxValue;
  END IF;
END;
$$ LANGUAGE plpgsql;
--4
SELECT xp('spec', 'id')
--5
SELECT * FROM spec
--6
SELECT xp('spec', 'id')
--7
SELECT * FROM spec
--8
CREATE TABLE test
(
    id integer NOT NULL
);
--9
INSERT INTO test VALUES (10);
--10
SELECT xp('test', 'id')
--11
SELECT * FROM spec
--12
SELECT xp('test', 'id')
--13
SELECT * FROM spec
--14
CREATE TABLE test2
(
    numValue1 integer NOT NULL,
	numValue2 integer NOT NULL
);
--15
SELECT xp('test2', 'numValue1')
--16
SELECT * FROM spec
--17
SELECT xp('test2', 'numValue1')
--18
SELECT * FROM spec
--19
INSERT INTO test2 VALUES (2, 13);
--20
SELECT xp('test2', 'numValue2')
--21
SELECT * FROM spec
--22
DROP FUNCTION xp(_table_name text, _column_name text)
--23
DROP TABLE spec;
DROP TABLE test;
DROP TABLE test2
