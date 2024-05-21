USE pubs;
-- Challenge 1 - Most Profiting Authors
-- Step 1: Calculate the royalties of each sales for each author
SELECT
	tt.title_id AS 'TITLE ID',
    au.au_id AS 'AUTHOR ID',
    tt.price * ss.qty * tt.royalty/100 * ta.royaltyper/100 AS sale_royalty
FROM 
	authors au
JOIN
	titleauthor ta ON ta.au_id=au.au_id
JOIN
	titles tt ON tt.title_id=ta.title_id
JOIN
	sales ss ON ss.title_id=tt.title_id;

-- Step 2: Aggregate the total royalties for each title for each author, I decided to include author's name although not requested 
SELECT 
    subquery.au_id AS 'AUTHOR ID',
    subquery.au_lname AS 'LAST NAME',
    subquery.au_fname AS 'FIRST NAME',
    subquery.title_id AS 'TITLE ID',
    SUM(subquery.sales_royalty) AS total_royalty
FROM 
    (SELECT 
        au.au_id,
        au.au_lname,
        au.au_fname,
        tt.title_id,
        tt.price * ss.qty * tt.royalty / 100 * ta.royaltyper / 100 AS sales_royalty
    FROM 
        authors au
    JOIN 
        titleauthor ta ON ta.au_id = au.au_id
    JOIN 
        titles tt ON tt.title_id = ta.title_id
    JOIN 
        sales ss ON ss.title_id = tt.title_id) subquery
GROUP BY 
    subquery.au_id, subquery.title_id;

-- Step 3: Calculate the total profits of each author, I decided to include author's name although not requested 
SELECT
	au.au_id AS 'AUTHOR ID',
    au.au_lname AS 'LAST NAME',
    au.au_fname AS 'FIRST NAME',
    SUM(tt.advance) + COALESCE(SUM(roy.total_royalty),0) AS total_profit
FROM 
	authors au
LEFT JOIN 
	titleauthor ta ON ta.au_id=au.au_id
LEFT JOIN
	titles tt ON tt.title_id=ta.title_id
LEFT JOIN
	(SELECT 
    subquery.au_id,
    subquery.title_id,
    SUM(subquery.sales_royalty) AS total_royalty
	FROM 
		(SELECT 
			au.au_id,
			au.au_lname,
			au.au_fname,
			tt.title_id,
			tt.price * ss.qty * tt.royalty / 100 * ta.royaltyper / 100 AS sales_royalty
		FROM 
			authors au
		JOIN 
			titleauthor ta ON ta.au_id = au.au_id
		JOIN 
			titles tt ON tt.title_id = ta.title_id
		JOIN 
			sales ss ON ss.title_id = tt.title_id) subquery
		GROUP BY 
			subquery.au_id, subquery.title_id) roy
		ON
			roy.au_id= au.au_id AND roy.title_id=tt.title_id
GROUP BY
	au.au_id
ORDER BY 
	total_profit DESC
LIMIT 3;

-- ALTERNATIVE SOLUTION USING TEMP TABLES
-- Step 1: Calculate sales royalty for each sale
CREATE TEMPORARY TABLE SalesRoyalties AS
SELECT 
    au.au_id AS author_id,
    au.au_lname AS last_name,
    au.au_fname AS first_name,
    tt.title_id AS title_id,
    tt.price * ss.qty * tt.royalty / 100 * ta.royaltyper / 100 AS sales_royalty
FROM 
    authors au
JOIN 
    titleauthor ta ON ta.au_id = au.au_id
JOIN 
    titles tt ON tt.title_id = ta.title_id
JOIN 
    sales ss ON ss.title_id = tt.title_id;
-- Step 2: Aggregate total royalties for each title
CREATE TEMPORARY TABLE TotalRoyalties AS
SELECT
	author_id,
    title_id,
    SUM(sales_royalty) AS total_royalty
FROM SalesRoyalties
GROUP BY
	author_id, title_id;
-- Step 3: Calculate total profits for each author
SELECT
	au.au_id AS 'AUTHOR ID', 
    au.au_lname AS 'LAST NAME',
    au.au_fname AS 'FIRST NAME',
    COALESCE(SUM(tt.advance),0) + COALESCE(SUM(tr.total_royalty),0) AS total_profit
FROM
	authors au
LEFT JOIN
	titleauthor ta on ta.au_id=au.au_id
LEFT JOIN 
	titles tt on tt.title_id=ta.title_id
LEFT JOIN
	TotalRoyalties tr on tr.author_id=au.au_id AND tr.title_id=tt.title_id
GROUP BY
	au.au_id
ORDER BY
	total_profit DESC;
LIMIT 3;

-- Challenge 3: create a permanent table named most_profiting_authors to hold the data about the most profiting authors. 
-- Create the permanent table
CREATE TABLE most_profiting_authors (
	au_id VARCHAR (11) NOT NULL,
    profits DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (au_id)
);


--  Insert the aggregated data into the permanent table
INSERT INTO most_profiting_authors (au_id, profits)
SELECT
	au.au_id, 
    COALESCE(SUM(tt.advance),0) + COALESCE(SUM(tr.total_royalty),0) AS total_profit
FROM
	authors au
LEFT JOIN
	titleauthor ta on ta.au_id=au.au_id
LEFT JOIN 
	titles tt on tt.title_id=ta.title_id
LEFT JOIN
	TotalRoyalties tr on tr.author_id=au.au_id AND tr.title_id=tt.title_id
GROUP BY
	au.au_id
ORDER BY
	total_profit DESC
LIMIT 3;