------------                       CREATE ROLE                        ----------
-- Create the role required by the framework schema
-- You will need to grant one of these roles, as appropriate, to the other
-- schemas built on top of the framework.

-- FULL is meant for developers and the framework consumer schema itself, so that
-- all aspects of the framework can be used.
CREATE ROLE &&fmwk_home+_full;

-- SELECT is meant for power users, reporting systems, etc that have no need of
-- access that allows modification to the base tables.
CREATE ROLE &&fmwk_home+_select;
