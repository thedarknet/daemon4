create or replace function static.objective_upsert
  ( p_quest_id    static.objective.quest_id%TYPE
  , p_obj_index   static.objective.obj_index%TYPE
  , p_desc        static.localized_text_detail.value%TYPE
  , p_count       static.objective.count%TYPE
  , p_activation_regex      static.objective.activation_regex%TYPE
  , p_fail_activation_regex   static.objective.fail_activation_regex%TYPE
  , p_reward_id         static.objective.reward_id%TYPE
  , p_objective_type        static.objective_type
  , p_remote_endpoint static.objective.remote_endpoint%TYPE
  , p_language  static.language
  )
returns integer AS $$
declare 
  v_desc_id static.localized_text.text_id%TYPE;
  v_objective_id static.objective.objective_id%TYPE;
begin
  select static.get_localized_text_id_or_insert(p_language,p_desc) into v_desc_id;

  INSERT INTO static.objective(
            objective_id, quest_id, obj_index, desc_id, count, activation_regex, 
            fail_activation_regex, reward_id, objective_type_enum, remote_endpoint)
    VALUES (DEFAULT, p_quest_id, p_obj_index, v_desc_id, p_count, p_activation_regex, 
            p_fail_activation_regex, p_reward_id, p_objective_type, p_remote_endpoint)
    ON CONFLICT ON CONSTRAINT objective_u0
  DO UPDATE 
  SET desc_id=v_desc_id
    , count=p_count
    , activation_regex=p_activation_regex
    , fail_activation_regex=p_fail_activation_regex
    , reward_id=p_reward_id
    , objective_type_enum=p_objective_type
    , remote_endpoint=p_remote_endpoint
  where static.objective.quest_id = p_quest_id and static.objective.obj_index = p_obj_index
    returning objective_id into v_objective_id;
    
  return v_objective_id;
end; $$
language PLPGSQL security definer;
;
