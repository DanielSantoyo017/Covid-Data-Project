--Tableau Table 1, Displaying the death percentage when considering the total cases and total deaths Globally
--Where continent is null, location is listed as an entire continent, which is not the correct information for the "location" column

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(new_Deaths AS INT))/SUM(new_cases) * 100 
AS Death_Percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Tableau Table 2, Displaying the total deaths per continents
--Locaiton NOT IN are values that are not realted to our areas of intrest which are specifcally continents
--Where continent is null, location is listed as an entire continent, which is not the correct information for the "location" column

SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCOunt
FROM CovidDeaths
WHERE Continent is NULL
AND location NOT IN ('world','European Union','International', 'Upper middle income','High income','Lower middle income','Low income')
GROUP BY location
ORDER BY TotalDeathCount desc

--Considering the mortality rate of COVID-19 reletive to the amount of cases as a percentage
--Where continent is null, location is listed as an entire continent, which is not the correct information for the "location" column 

SELECT continent, Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Mortality_Percentage
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Examining the total populaiton that has been infected with COVID-19 as a percentage wihtin the context of the date

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Percent_Infected
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Examining the total ammount of the U.S. populaiton infected with COVID-19 as a percentage within the the context of the date

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Percent_Infected_US
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2

--Considering what countrys have had the highest rate of COVID-19 infection releative to population calculated as a percentage

SELECT location, MAX(total_cases) AS Highest_Infection_Count, population, date, (MAX(total_cases)/population)*100 AS Percent_Popluation_infected
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY Percent_Popluation_infected DESC

--Exploring what contries have had high mortqlity rates due to COVID-19
--"total_deaths" listed as VARCHAR, did not allow for correct ordering, chnaegd to INT using CAST Function

SELECT location, MAX(CAST(total_deaths AS INT)) Hightest_Death_Count
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Hightest_Death_Count DESC


--EXPLORING DATA BY CONTINENT (for tableau)

--Continent with highest mortality counts
--"total_deaths" listed as VARCHAR, did not allow for correct ordering, chnaegd to INT using CAST Function
--Table 4
SELECT continent, MAX(CAST(total_deaths AS INT)) Hightest_Continent_Death_Count
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Hightest_Continent_Death_Count DESC

--Considering what continents have had the highest rate of COVID-19 infection releative to population 

SELECT continent, MAX(total_cases) AS Highest_Infection_Count, population, (MAX(total_cases)/population)*100 AS Percent_Popluation_infected
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population, Date
ORDER BY Percent_Popluation_infected DESC

--GLOBAL data on COVID-19 starting from 2020/01/01
--"New Deaths" is listed as VARCHAR and to allow this query to function it needs to be an INT, Used CAST function
--Calculating the percent of the population that has deid by taking total global deaths, and divding total global cases as fluctuation occurs daily

SELECT date, SUM(new_cases) AS Total_Golbal_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Global_Deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS Death_Percentage
FROM [Covid Data Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--Join between CovidDeaths table and CovidVaccinations table
--Considering the ammount of poeple in the world that have been vaccinated for COVID-19 as a percentage
-- "BIGINT" used to avoid "Arithmaetic Overflow Error"

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, 
Deaths.date) AS Rolling_Vaccination_Count, 
(SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, 
Deaths.date)/Deaths.population) * 100 AS Percent_Vaccinated
FROM [Covid Data Project 1].dbo.CovidDeaths AS Deaths
JOIN [Covid Data Project 1].dbo.CovidVaccinations AS Vax
	ON Deaths.location = Vax.location 
	AND Deaths.date = Vax.date	
WHERE Deaths.continent IS NOT NULL
ORDER by 2,3


--Using a CTE to calculate the percentage of the populaiton vaccinated in each conitnent and respective locaiton

WITH PopoulationVaccinations (continent, location, date, population, new_vaccinations, Rolling_Vaccination_Count) AS
(
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, 
Deaths.date) AS Rolling_Vaccination_Count
FROM [Covid Data Project 1].dbo.CovidDeaths AS Deaths
JOIN [Covid Data Project 1].dbo.CovidVaccinations AS Vax
	ON Deaths.location = Vax.location 
	AND Deaths.date = Vax.date	
WHERE Deaths.continent IS NOT NULL
)
SELECT *, (Rolling_Vaccination_Count/population) * 100 AS Percent_Population_Vaccinated
FROM PopoulationVaccinations 

--Creating Temp Table with COVID-19 Data to keep a rolling count of the population vaccinated from each continent as new vaccinations rise daily 

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent nVARCHAR(255),
location nVARCHAR(255),
Date datetime,
Population numeric, 
New_vaccinations numeric, 
Rolling_Vaccination_Count numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vax.new_vaccinations,
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, 
Deaths.date) AS Rolling_Vaccination_Count
FROM [Covid Data Project 1].dbo.CovidDeaths AS Deaths
JOIN [Covid Data Project 1].dbo.CovidVaccinations AS Vax
	ON Deaths.location = Vax.location 
	AND Deaths.date = Vax.date	
WHERE Deaths.continent IS NOT NULL

SELECT *
FROM #PercentPopulationVaccinated