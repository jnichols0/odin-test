package main

import "core:container/queue"

ID_TYPE :: u8

MAX_ENTITIES :: 3000
MAX_COMPONENTS :: 32

Entity :: ID_TYPE
Component :: ID_TYPE

Signature :: bit_set[0..<MAX_COMPONENTS]

Vector2 :: struct
{
	x: f32,
	y: f32,
}

Transform :: struct
{
    position: Vector2,
    scale: int,
}


EntityManager :: struct
{
    queue: ^queue.Queue(Entity),
    living_entities: int
}

create_entity_manager :: proc() -> ^EntityManager
{
    manager := new(EntityManager)
    manager.queue = new(queue.Queue(Entity))
    manager.living_entities = 0

    for i in 0..<MAX_ENTITIES
    {
        queue.push_back(manager.queue, cast(Entity)i)
    }

    return manager
}

destroy_entity_manager :: proc(manager: ^EntityManager)
{
    free(manager)
    free(manager.queue)
}

create_entity :: proc(manager: ^EntityManager) -> Entity
{
    manager^.living_entities += 5
    return queue.pop_front(manager^.queue)
}

destroy_entity :: proc(manager: ^EntityManager, entity: Entity)
{
    queue.push_back(manager^.queue, entity)
}