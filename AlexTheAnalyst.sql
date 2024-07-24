/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * 
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
ORDER BY 3,4;


-- Select Data that we are going to be starting with

SELECT `location`, `date`, total_cases, new_cases, total_deaths, population
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
ORDER BY 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT `location`, `date`, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM sql_data_exploration.covid_deaths
WHERE `location` like '%kenya%'
ORDER BY 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT `location`, `date`, population, total_cases, (total_cases/population)*100 as infected_percentage
FROM sql_data_exploration.covid_deaths
WHERE `location` like '%kenya%'
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population

SELECT `location`, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 as infected_percentage
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
GROUP BY `location`, population
ORDER BY infected_percentage DESC;


-- Countries with Highest Death Count per Population

SELECT `location`, MAX(CONVERT(total_deaths, UNSIGNED)) AS total_death_count
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
GROUP BY `location`
ORDER BY total_death_count DESC;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

-- METHOD 1

-- SELECT `location`, MAX(CONVERT(total_deaths, UNSIGNED)) AS total_death_count
-- FROM sql_data_exploration.covid_deaths
-- WHERE continent = ''
-- GROUP BY `location`
-- ORDER BY total_death_count DESC;

-- METHOD 2	

SELECT `continent`, MAX(CONVERT(total_deaths, UNSIGNED)) AS total_death_count
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
GROUP BY `continent`
ORDER BY total_death_count DESC;



-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM sql_data_exploration.covid_deaths
WHERE continent <> ''
-- GROUP BY `date`
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.`location`, dea.`date`, dea.population, vac.new_vaccinations, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS rolling_people_vaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM sql_data_exploration.covid_deaths dea
JOIN sql_data_exploration.covid_vaccinations vac
	ON dea.`location` = vac.`location`
	AND dea.`date` = vac.`date`
WHERE dea.continent <> ''
ORDER BY 1, 2, 3


-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, `location`, `date`, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.`location`, dea.`date`, dea.population, vac.new_vaccinations, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS rolling_people_vaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM sql_data_exploration.covid_deaths dea
JOIN sql_data_exploration.covid_vaccinations vac
	ON dea.`location` = vac.`location`
	AND dea.`date` = vac.`date`
WHERE dea.continent <> ''
-- ORDER BY 1, 2, 3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_vaccinated
FROM pop_vs_vac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMPORARY TABLE percent_population_vaccinated
(
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    COALESCE(vac.new_vaccinations, 0), -- Convert empty string to 0
    SUM(COALESCE(vac.new_vaccinations, 0)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS rolling_people_vaccinated
FROM sql_data_exploration.covid_deaths dea
JOIN sql_data_exploration.covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '';

SELECT *, 
       (rolling_people_vaccinated / population) * 100 AS percentage_vaccinated
FROM percent_population_vaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW percent_population_vaccinated
SELECT dea.continent, dea.`location`, dea.`date`, dea.population, vac.new_vaccinations, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.`location` ORDER BY dea.`location`, dea.`date`) AS rolling_people_vaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM sql_data_exploration.covid_deaths dea
JOIN sql_data_exploration.covid_vaccinations vac
	ON dea.`location` = vac.`location`
	AND dea.`date` = vac.`date`
WHERE dea.continent <> ''
