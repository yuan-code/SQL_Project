
  -- Two data table: Covid Deaths and Covid Vaccinations
  SELECT COUNT(*)
  FROM [ProjectCovid].[dbo].[CovidDeaths]

  SELECT COUNT(*)
  FROM  [ProjectCovid].[dbo].[CovidVaccinations]


  -- check variable type
  EXEC sp_help 'dbo.[CovidDeaths]'
  EXEC sp_help 'dbo.[CovidVaccinations]'


  SELECT *
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL
  ORDER BY location, date


-- Total Cases vs. Total Deaths
-- Shows likelihood of dying in these countries
  SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float, total_cases))*100 AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE location IN ('Canada', 'United States', 'China') AND continent IS NOT NULL
  ORDER BY location, date


-- Toal Cases vs. Population
-- Shows what percentage of population infected with Covid
  SELECT location, date, total_cases, population, (CONVERT(float, total_cases)/population)*100 AS PercentPopulationInfected
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE location IN ('Canada', 'United States', 'China') AND continent IS NOT NULL
  ORDER BY location, date


-- Countries with Highest Infection Rate Compared to Population
  SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CONVERT(float, total_cases)/population)*100)  AS PercentPopulationInfected
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  GROUP BY location, population
  ORDER BY PercentPopulationInfected DESC


  -- Countries with Highest Death Rate per Population
  SELECT location, population, MAX(CONVERT(float, total_deaths)) AS TotalDeathCnt, (MAX(CONVERT(float, total_deaths))/population*100) AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  GROUP BY location, population
  ORDER BY DeathPercentage DESC


  -- Break Down by Continent
  -- Showing continents with the Total Death Count per Total Population Before 2023-09-10
  SELECT continent, SUM(NULLIF(CONVERT(float, total_deaths), 0))*100/SUM(population) AS DeathPercentContinent
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND TRIM(continent) <> ' ' AND date = '2023-09-10'
  GROUP BY continent
  ORDER BY DeathPercentContinent DESC


  -- Global Numbers from 2020-01-01 to 2023-09-19 in total
  SELECT SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND TRIM(continent) <> ' '
  ORDER BY total_death, total_case


  -- Global Numbers from 2020-01-01 to 2023-09-19
  SELECT date, SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death , SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND TRIM(continent) <> ' '
  GROUP BY date
  ORDER BY date


  -- Total Population vs. Vaccinations
  -- Shows Percentage of Population that has recieved at least one Covid Vaccine
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM [ProjectCovid].[dbo].[CovidDeaths] dea
  JOIN [ProjectCovid].[dbo].[CovidVaccinations] vac 
  ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL AND TRIM(dea.continent) <> ' '
  ORDER BY dea.location, dea.date


  WITH CTE AS
  (	
	  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	  FROM [ProjectCovid].[dbo].[CovidDeaths] dea
	  JOIN [ProjectCovid].[dbo].[CovidVaccinations] vac 
	  ON dea.location = vac.location AND dea.date = vac.date
	  WHERE dea.continent IS NOT NULL AND TRIM(dea.continent) <> ' '
	  
  )
  SELECT *, (RollingPeopleVaccinated/population)*100 AS VacPerPop
  FROM CTE
  ORDER BY location, date
  

  -- Using Temp Table to perform Calculation in previous query
  DROP TABLE IF EXISTS #PercentPopulationVaccinated
  CREATE TABLE #PercentPopulationVaccinated
  (
  continent nvarchar(255),
  location nvarchar(255),
  date datetime,
  population numeric,
  new_vaccinations numeric,
  RollingPeopleVaccinated numeric
  )

  INSERT INTO #PercentPopulationVaccinated
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM [ProjectCovid].[dbo].[CovidDeaths] dea
  JOIN [ProjectCovid].[dbo].[CovidVaccinations] vac 
  ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL AND TRIM(dea.continent) <> ' '
	  

  SELECT *, (RollingPeopleVaccinated/population)*100 AS VacPerPop
  FROM #PercentPopulationVaccinated
  ORDER BY location, date


  -- Create View to store data for later visualization
  CREATE VIEW PercentPopulationVaccinated AS
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM [ProjectCovid].[dbo].[CovidDeaths] dea
  JOIN [ProjectCovid].[dbo].[CovidVaccinations] vac 
  ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL AND TRIM(dea.continent) <> ' '

  SELECT *
  FROM PercentPopulationVaccinated


  /* Queries used for Tableau Visualization */

  -- Global Numbers from 2020-01-01 to 2023-09-19 in total
  SELECT SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND TRIM(continent) <> ' '
  ORDER BY total_death, total_case


  SELECT location, SUM(new_deaths) AS TotalDeathCNT
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE TRIM(continent) = ' ' AND location NOT IN ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
  GROUP BY location
  ORDER BY TotalDeathCNT DESC

  SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CONVERT(float, total_cases)/population)*100)  AS PercentPopulationInfected
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  GROUP BY location, population
  ORDER BY PercentPopulationInfected DESC

  SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((CONVERT(float, total_cases)/population)*100)  AS PercentPopulationInfected
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  GROUP BY location, population, date
  ORDER BY PercentPopulationInfected DESC

  SELECT location, SUM(new_deaths) AS TotalDeathCNT
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE TRIM(continent) = ' ' AND location IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
  GROUP BY location
  ORDER BY TotalDeathCNT DESC

  SELECT location, date, total_cases, total_deaths, population, (CONVERT(float, total_deaths)/CONVERT(float, total_cases))*100 AS DeathPercentage
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND (TRIM(continent) <> ' ' OR location = 'World')
  ORDER BY location, date

  -- New Cases/Deaths in Each Country
  SELECT location, date, new_cases, new_deaths
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND (TRIM(continent) <> ' ')
  ORDER BY location, date

  -- Keep Total Cases and Total Deaths in the last date
  SELECT location, population, total_cases AS Confirmed, total_deaths AS Deceased 
  FROM [ProjectCovid].[dbo].[CovidDeaths]
  WHERE continent IS NOT NULL AND TRIM(continent) <> ' ' AND date = '2023-09-13'
  ORDER BY location