SELECT * FROM layoffs;

CREATE TABLE layoffs_staging    -- creating duplicate for playground
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;
-- 1 removing duplicates
WITH duplicate_cte AS
(
SELECT * ,ROW_NUMBER() OVER( 
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country
, funds_raised_millions) as row_num 
FROM  layoffs_staging 
)
SELECT * FROM duplicate_cte WHERE row_num > 1;   -- identifying duplicates

CREATE TABLE `layoffs_staging2` (    -- creating another as del from cte NA
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT * ,ROW_NUMBER() OVER( 
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country
, funds_raised_millions) as row_num 
FROM  layoffs_staging ;

SELECT * FROM layoffs_staging2;
DELETE FROM layoffs_staging2 WHERE row_num > 1;  -- duplicates removed

-- 2 standardization
SELECT company, TRIM(company) FROM layoffs_staging2;  -- TRIM removes the empty sapces on left
UPDATE layoffs_staging2 SET company = TRIM(company);

SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY 1;  -- checking industry colmn, ~ check other colmns too
SELECT * FROM layoffs_staging2 WHERE industry LIKE 'Crypto%';  -- checking crypto values
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)   -- removes . at the end of country
FROM layoffs_staging2 ORDER BY 1;
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');   -- formatting date colmn
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;     -- changing the dt 

-- 3 checking on null & missing vals
SELECT * FROM layoffs_staging2 WHERE industry IS NULL OR industry = '';   
SELECT * FROM layoffs_staging2 WHERE company = 'Airbnb';

SELECT t1.industry, t2.industry     -- checking using select 
FROM layoffs_staging2 t1 
JOIN layoffs_staging2 t2
	ON t1.company = t2.company AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2    -- changing blanks to nulls
SET industry = NULL WHERE industry = '';

UPDATE layoffs_staging2 t1   -- filling using update
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- 4 remove unnecessary colmns
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL; 

DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL; 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;