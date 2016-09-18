ALTER TABLE ONLY static.epic_required_epics
    ADD CONSTRAINT epic_required_epics_c0 CHECK (target_epic_id != required_epic_id);
